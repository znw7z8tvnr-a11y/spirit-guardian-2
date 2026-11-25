# 獨立優化批次：暫用音效波形快取與播放器重用

範圍是既有穩定 M2 的 audio 模組。Lab 目前未接入這份音效，本批不修改 Lab 主程式或宣稱 Lab 已有音樂。音效仍是暫用短合成音，並未移植原 HTML 完整音樂／音訊設定，也不是正式美術與音樂驗收。

相同頻率共用不可修改的 AudioStreamWAV，四個已支援元素與其餘元素的備用音最多五份波形。重複音效重用 AudioStreamPlayer，完成時回到閒置池；仍保留最多八個同時聲音、原本 90ms 節流、100ms 波形長度與預設靜音。播放器用 busy 狀態等待 finished，不因 playing 剛轉 false 就提早借出。場景結束時由父節點釋放，池內物件與波形保留是有界的快取，不宣稱降低所有時刻的常駐記憶體。

public cue(element)、muted、clock、voices 與 MAX_VOICES 保留。沒有改動傷害、掉率、連鎖、存檔或音效開關 UI。未知名稱共用原本 247Hz 備用音，不累積任意名稱快取；靜音和超額／節流拒絕時不產生新波形或播放器。靜音後已開始的短音尾巴仍按原本行為自然結束。

修改 audio.gd，新增 audio_pool.gd 與 test_audio_web.py，並加入原生／瀏覽器清單與局部驗收依賴。Godot 4.6.3 匯入、Lab 解析及 audio 21／integration 18／modules 39／localization 21／touch 20 共 119 項檢查通過；音效內部方法改為私有命名後只重跑 audio，其餘程式行為未變。Python 選測／錯誤處理 25 項通過。

音效原生測試逐樣本對照原波形、資料格式與取樣率，驗證快取身分、未知名稱共用、上限八個節點／聲音、25 輪重用不再建立播放器、完成回呼不重複、閒置完成事件不把計數變負、靜音與時鐘語意。dummy 音訊環境的完成事件由測試明確模擬，不當成實際出聲證據。

Web 結果見 browser/audio-web.json：M2 橫向 1180×820、直向 820×1180 均以實際觸控開／關音效，確認預設靜音、啟用後非零混音訊號、關閉後短音結束回到靜音、再次啟用恢復，以及 44 CSS px 操作目標。Web Audio Analyser 只接旁路觀察混音，不改遊戲狀態、不強制 resume AudioContext，也未加入免使用者手勢的 autoplay 旗標。量測在音訊圖內，不等同作業系統喇叭或真人聽感驗收，無 pageerror 或引擎錯誤。

交付專案保留原 project.godot，預設執行穩定 M2 場景以便測試音效；完整 Lab 原始碼仍在 experiments/chain_lab，但本批不接入 Lab 音效。獨立版本、不移動舊標記、不更新線上站。iPad Safari／音訊中斷／真實裝置延遲尚未驗收；未跑完整 Lab 20 波或全部技能，也不宣稱 FPS 提升。
