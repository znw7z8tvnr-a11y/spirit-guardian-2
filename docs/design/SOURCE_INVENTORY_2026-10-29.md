# 原始功能盤點第一批（2026-10-29）

這是來源與實作差距表，不是完整移植驗收。11個補充HTML逐檔SHA-256核對未改；資料為22技能、19寶石、50組唯一配方。

| 技能 | V9觀察到的選敵 | M2.1 | Lab V2 |
|---|---|---|---|
| 爆裂火球 | radius around primary target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 寒冰長槍 | radius around primary target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 連鎖雷電 | within 165 of target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 毒霧 | primary target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 流星雨 | radius around primary target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 奧術飛彈 | radius around primary target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 迴旋月刃 | radius around primary target | catalog only; behavior port pending | not implemented |
| 穿透射線 | horizontal strip around target | catalog only; behavior port pending | Lab horizontal lightning strip; see PIERCE_SPELL.md |
| 土刺 | radius around primary target | catalog only; behavior port pending | not implemented |
| 颶風 | radius around primary target | catalog only; behavior port pending | not implemented |
| 聚焦光束 | horizontal strip around target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 旋轉法球 | radius around primary target | catalog only; behavior port pending | not implemented |
| 熔岩裂隙 | radius around primary target | catalog only; behavior port pending | not implemented |
| 引力漩渦 | radius around primary target | catalog only; behavior port pending | not implemented |
| 幽靈守衛 | primary target | catalog only; behavior port pending | not implemented |
| 荊棘護城 | radius around primary target | catalog only; behavior port pending | not implemented |
| 火花術 | within 165 of target | catalog only; behavior port pending | not implemented |
| 雷電風暴 | radius around primary target | catalog only; behavior port pending | not implemented |
| 暴風雪 | radius around primary target | catalog only; behavior port pending | not implemented |
| 冰霜新星 | radius around primary target | partial runnable behavior | provisional runnable behavior; see EIGHT_SPELLS.md |
| 毒沼 | radius around primary target | catalog only; behavior port pending | not implemented |
| 骷髏召喚 | primary target | catalog only; behavior port pending | not implemented |

來源：reference_modules/spirit_guardian_gem_chain_module_v9_integrated.html 的 executeCast 與選敵分組；精確行數、原數值及檔案雜湊見同名JSON。

待做：逐招對照V32、技能／VFX模組；完整怪物Boss能力與掉肉表；素材商用授權。不要因名稱而宣稱完整召喚AI或持續區域已存在／已移植。

配方仍有12素材分類與新元素概念的衝突，先保存原資料，不自行刪除或把170個未定義組合當成完成法術。
