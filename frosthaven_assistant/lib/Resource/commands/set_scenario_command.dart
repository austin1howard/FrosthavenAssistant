
import 'dart:math';

import 'package:frosthaven_assistant/Resource/stat_calculator.dart';

import '../../Layout/main_list.dart';
import '../../Model/scenario.dart';
import '../../services/service_locator.dart';
import '../action_handler.dart';
import '../enums.dart';
import '../game_methods.dart';
import '../game_state.dart';
import '../loot_deck_state.dart';

class SetScenarioCommand extends Command {
  final GameState _gameState = getIt<GameState>();
  late final String _scenario;
  late final bool section;

  SetScenarioCommand(this._scenario, this.section);

  @override
  void execute() {

    if (!section) {
      //first reset state
      _gameState.round.value = 1;
      _gameState.currentAbilityDecks.clear();
      _gameState.scenarioSpecialRules.clear();
      List<ListItemData> newList = [];
      for (var item in _gameState.currentList) {
        if (item is Character) {
          if (item.characterClass.name != "Objective" && item.characterClass.name != "Escort") {
            //newList.add(item);item.characterState.initiative = 0;

            item.characterState.health.value =
            item.characterClass.healthByLevel[item.characterState.level.value -
                1];
            item.characterState.maxHealth.value = item.characterState.health.value;
            item.characterState.xp.value = 0;
            item.characterState.conditions.value.clear();
            item.characterState.summonList.value.clear();

            if(item.id == "Beast Tyrant") {
              //create the bear summon
              final int bearHp = 8 + item.characterState.level.value * 2;
              MonsterInstance bear = MonsterInstance.summon(
                  0, MonsterType.summon, "Bear", bearHp, 3, 2, 0, "beast", -1);
              item.characterState.summonList.value.add(bear);
            }

            newList.add(item);
          }
        }
      }
      GameMethods.shuffleDecks();
      _gameState.modifierDeck.initDeck("");
      _gameState.modifierDeckAllies.initDeck("Allies");
      _gameState.currentList = newList;


      //loot deck init
      if (_scenario != "custom") {
        LootDeckModel? lootDeckModel = _gameState.modelData.value[_gameState
            .currentCampaign.value]!.scenarios[_scenario]!.lootDeck;
        if (lootDeckModel != null) {
          _gameState.lootDeck = LootDeck(lootDeckModel, _gameState.lootDeck);
        } else {
          _gameState.lootDeck = LootDeck.from(_gameState.lootDeck);
        }
      }

      GameMethods.clearTurnState(true);
      _gameState.toastMessage.value = "";
    }


    List<String> monsters = [];
    List<SpecialRule> specialRules = [];
    String initMessage = "";
    if (section) {
      monsters = _gameState.modelData.value[_gameState
          .currentCampaign.value]!.sections[_scenario]!.monsters;

      specialRules = _gameState.modelData.value[_gameState
          .currentCampaign.value]!.sections[_scenario]!.specialRules.toList();

      initMessage = _gameState.modelData.value[_gameState
          .currentCampaign.value]!.sections[_scenario]!.initMessage;
    }else{
      if(_scenario != "custom") {
        monsters = _gameState.modelData.value[_gameState
            .currentCampaign.value]!.scenarios[_scenario]!.monsters;
        specialRules = _gameState.modelData.value[_gameState
            .currentCampaign.value]!.scenarios[_scenario]!.specialRules.toList();
        initMessage = _gameState.modelData.value[_gameState
            .currentCampaign.value]!.scenarios[_scenario]!.initMessage;
      }
    }

    //handle special rules
    for (String monster in monsters) {
      int levelAdjust = 0;
      Set<String> alliedMonsters = {};
      for (var rule in specialRules) {
        if(rule.name == monster) {
          if(rule.type == "LevelAdjust") {
            levelAdjust = rule.level;
          }
        }
        if(rule.type == "Allies"){
          for (String item in rule.list){
            alliedMonsters.add(item);
          }
        }
      }

      bool add = true;
      for (var item in _gameState.currentList) {
        //don't add duplicates
        if(item.id == monster) {
          //TODO: does not handle problems with allies?
          add = false;
          break;
        }
      }
      if(add) {
        bool isAlly = false;
        if(alliedMonsters.contains(monster)){
          isAlly = true;
        }
        _gameState.currentList.add(GameMethods.createMonster(
            monster, min(_gameState.level.value + levelAdjust, 7), isAlly)!);
      }
    }

    //add objectives and escorts
    for(var item in specialRules) {
      if(item.type == "Objective"){
        Character objective = GameMethods.createCharacter("Objective", item.name, _gameState.level.value+1)!;
        objective.characterState.maxHealth.value = StatCalculator.calculateFormula(item.health.toString())!;
        objective.characterState.health.value = objective.characterState.maxHealth.value;
        objective.characterState.initiative.value = item.init;
        bool add = true;
        for (var item2 in _gameState.currentList) {
          //don't add duplicates
          if(item2 is Character && (item2).characterState.display.value == item.name) {
            add = false;
            break;
          }
        }
        if(add) {
          _gameState.currentList.add(objective);
        }
      }
      if (item.type == "Escort") {
        Character objective = GameMethods.createCharacter("Escort", item.name, _gameState.level.value+1)!;
        objective.characterState.maxHealth.value = StatCalculator.calculateFormula(item.health.toString())!;
        objective.characterState.health.value = objective.characterState.maxHealth.value;
        objective.characterState.initiative.value = item.init;
        bool add = true;
        for (var item2 in _gameState.currentList) {
          //don't add duplicates
          if(item2 is Character && (item2).characterState.display.value == item.name) {
            add = false;
            break;
          }
        }
        if(add) {
          _gameState.currentList.add(objective);
        }
      }
    }

    if (!section) {
      _gameState.scenarioSpecialRules = specialRules;
      GameMethods.updateElements();
      GameMethods.updateElements(); //twice to make sure they are inert.
      GameMethods.setRoundState(RoundState.chooseInitiative);
      GameMethods.sortCharactersFirst();
      _gameState.scenario.value = _scenario;
    }else {
      _gameState.scenarioSpecialRules.addAll(specialRules);
    }

    //Future.delayed(Duration(milliseconds: 10), () {
      _gameState.updateList.value++;
      MainList.scrollToTop();
    //});

    //show init message if exists:
    if(initMessage.isNotEmpty) {
      _gameState.toastMessage.value = initMessage;
    }
  }

  @override
  void undo() {
    _gameState.updateList.value++;
  }

  @override
  String describe() {
    if(!section) {
      return "Set Scenario";
    }
    return "Add Section";
  }
}