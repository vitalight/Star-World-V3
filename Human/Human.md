# Star World

## Game Reference

Star World is a tower-defense game. It uses Godot. It is inspired by Arknights（明日方舟）.

## Art Reference

![](ArtReference.jpg)

初始资源在：StarterContent目录中

## Philosophy

- 每个模块（美术效果，程序逻辑），都先单独进行开发，通过review再进行集成。减少不必要的耦合，提升开发效率。

## Goal

- 开发者关卡，包含四个子界面：
    - Blueprint：imagegen生成的游戏概念图（参考图，塔防界面）
    - Art Test：只看资产（1）Character（2）Effect（3）Battle（包括UI，但无实机逻辑）
    - Logic Test：只看逻辑（1）极简战斗场景（全用极简占位素材）
    - Game Test：资产+逻辑集成（1）实机战斗场景

初阶段首要目的，是开发一个高效率、低耦合的开发者工具。

让网页上的ai总结明日方舟玩法，再实现。

## Todo

- [ ] Player Mode
    - [ ] 设计第一章关卡
    - [ ] 平衡第一章数值
- [ ] Extra
    - [ ] 教学系统：教玩家怎么玩 
    - [ ] 干员技能树（消耗金币）
    - [ ] 存档系统：支持多个存档   

【参考图片，更新第一章战斗关卡】
- 第二关："C:\Users\vital\Desktop\level0-3.png"。需要支持飞行敌人的出生点（飞行敌人从高台出生，考虑制作新素材）
- 第三关："C:\Users\vital\Desktop\level0-4.png"
boss战增加至两场。（第四关和第五关）
- 第四关："C:\Users\vital\Desktop\level-tr-11.png"
- 第五关："C:\Users\vital\Desktop\level0-6.png"

【使用imagegen，更新地形标识】
- 第一行：地面1，地面2，不可部署地面1,不可部署地面2
- 第二行：高台1，高台2，不可部署高台1，不可部署高台2
- 第三行：特殊地面1，特殊地面2，特殊地面3，特殊地面4
- 第四行：特殊高台1，特殊高台2，特殊高台3，特殊高台4
（地面和高台，应该使用不同的色系进行区分）
（特殊：后续会加特殊效果，比如持续治疗、持续伤害、增加防御）

【更新角色技能】
参考：D:\_Zyen\2_Codes\StarWorldV3\Human\GameContent.md，技能表部分