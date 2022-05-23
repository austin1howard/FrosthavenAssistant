import 'dart:collection';
import 'dart:core';

import 'package:frosthaven_assistant/Model/MonsterAbility.dart';
import 'package:frosthaven_assistant/Model/character_class.dart';
import 'package:frosthaven_assistant/Model/monster.dart';

class ScenarioModel {
  ScenarioModel({required this.monsters});
  List<String> monsters;
  factory ScenarioModel.fromJson(Map<String, dynamic> data) {
    final monsters = data['monsters'] as List<dynamic>;
    List<String> monsterList = [];
    for (var monster in monsters) {
      monsterList.add(monster);
    }
    //TODO: add other scensrio stuff like special rules and sections
    return ScenarioModel(monsters: monsterList);
  }

}

class CampaignModel {
  CampaignModel({required this.edition, required this.monsterAbilities, required this.monsters, required this.characters, required this.scenarios,});
  final String edition;
  final List<MonsterAbilityDeckModel> monsterAbilities;
  final List<MonsterModel> monsters;
  final List<CharacterClass> characters;
  final Map< String, ScenarioModel> scenarios;
  //TODO: add classes and scenarios (sections are part of scenarios)

  factory CampaignModel.fromJson(Map<String, dynamic> data) {
    // note the explicit cast to String
    // this is required if robust lint rules are enabled
    final edition = data['edition'] as String;
    final monsterAbilities = data['monsterAbilities'] as List<dynamic>;
    List<MonsterAbilityDeckModel> deckDataList = [];
    for (var item in monsterAbilities) {
      deckDataList.add(MonsterAbilityDeckModel.fromJson(item));
    }
    final monsters = data['monsters'] as List<dynamic>;
    List<MonsterModel> monsterDataList = [];
    for (var item in monsters) {
      monsterDataList.add(MonsterModel.fromJson(item));
    }

    List<CharacterClass> characterDataList = [];
    final classes = data['classes'] as List<dynamic>;
    for (var item in classes) {
      characterDataList.add(CharacterClass.fromJson(item));
    }

    Map<String, ScenarioModel> scenarioMap = HashMap();
    final scenarios = data['scenarios'] as Map<dynamic, dynamic>;
    for (String key in scenarios.keys){
      scenarioMap[key] = ScenarioModel.fromJson(scenarios[key]);
    }
    return CampaignModel(edition: edition, monsterAbilities: deckDataList, monsters: monsterDataList, characters: characterDataList, scenarios: scenarioMap);
  }
}