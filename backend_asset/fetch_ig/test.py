import os
import re
import json
import shutil
import requests
from tqdm import tqdm
from instaloader import Instaloader, Post

def download_file(url, save_path, desc="下載"):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        total_size = int(response.headers.get('content-length', 0))
        with open(save_path, 'wb') as file, tqdm(desc=desc, total=total_size, unit='iB', unit_scale=True, leave=False) as bar:
            for data in response.iter_content(chunk_size=1024):
                bar.update(file.write(data))
        return True
    except Exception as e:
        print(f"❌ {desc} 失敗: {e}")
        return False

def run_auto_ingest():
    L = Instaloader()
    
    # ====== 1. 基本資訊輸入 ======
    print("=== 🚗 汽車資料半自動歸類系統 ===")
    url = input("🔗 請輸入 IG 貼文或 Reel 網址: ").strip()
    brand = input("🏢 請輸入汽車品牌 (例如 Benz, Audi): ").strip()
    model = input("🚘 請輸入車型型號 (例如 AMG_GTR, RS6_Avant): ").strip()
    
    # 建立基礎路徑 (請確保 D: 槽存在，或改成你實際的硬碟代號)
    target_base_dir = f"D:/{brand}/{model}"
    cover_dir = os.path.join(target_base_dir, "images", "cover")
    detail_dir = os.path.join(target_base_dir, "images", "detail")
    sound_dir = os.path.join(target_base_dir, "sound")
    
    os.makedirs(cover_dir, exist_ok=True)
    os.makedirs(detail_dir, exist_ok=True)
    os.makedirs(sound_dir, exist_ok=True)

    try:
        # ====== 2. 抓取 IG 資料 ======
        match = re.search(r"/(p|reel)/([^/?]+)", url)
        if not match:
            print("❌ 網址解析錯誤！")
            return
        shortcode = match.group(2)
        print(f"📡 正在從 IG 獲取中繼資料...")
        post = Post.from_shortcode(L.context, shortcode)
        
        # ====== 3. 互動式補充欄位 (按 Enter 可跳過帶預設) ======
        print("\n📝 請補充汽車規格 (直接按 Enter 可稍後在 JSON 內修改):")
        price = input("💰 價格 (預設 0): ").strip() or "0"
        engine = input("🔧 引擎規格 (例如 4.0 L V8 雙渦輪增壓): ").strip() or "未知"
        horsepower = input("🐎 馬力 (預設 0): ").strip() or "0"
        country = input("🌍 製造國家 (例如 Germany): ").strip() or "未知"
        vehicle_type = input("🏁 車款類型 (例如 頂級跑車): ").strip() or "跑車"
        
        # ====== 4. 下載並自動重新命名檔案 ======
        print("\n📥 開始下載 IG 媒體檔案...")
        media_nodes = list(post.get_sidecar_nodes()) if post.typename == 'GraphSidecar' else [post]
        detail_count = 0
        
        for idx, node in enumerate(media_nodes):
            # 第一張圖做為封面 cover.jpg，其餘放 detail
            if idx == 0:
                img_url = node.video_url if node.is_video else node.display_url
                # 下載封面
                download_file(img_url, os.path.join(cover_dir, "cover.jpg"), desc="下載封面圖")
                # 順便下載作者大頭貼 (選擇性，這裡先用封面代替或不抓)
                shutil.copyfile(os.path.join(cover_dir, "cover.jpg"), os.path.join(cover_dir, "author.jpg"))
                shutil.copyfile(os.path.join(cover_dir, "cover.jpg"), os.path.join(cover_dir, "stock.jpg"))
            
            # 所有圖片（包含第一張）都可以當成 detail 輪播圖
            if not node.is_video:
                detail_count += 1
                # 自動補零命名：p01.jpg, p02.jpg ...
                detail_filename = f"p{detail_count:02d}.jpg"
                download_file(node.display_url, os.path.join(detail_dir, detail_filename), desc=f"下載詳細圖 {detail_filename}")

        # ====== 5. 引擎聲檔案處理 ======
        has_sound = False
        sound_file_path = ""
        print(f"\n🎵 偵測到本地 sound 資料夾: {sound_dir}")
        print("💡 請手動將該車款的 .mp3 檔放入上述路徑。")
        sound_check = input("❓ 請問您放好聲音檔案了嗎？(y/n, 預設 n): ").strip().lower()
        if sound_check == 'y':
            mp3_files = [f for f in os.listdir(sound_dir) if f.endswith('.mp3')]
            if mp3_files:
                has_sound = True
                sound_file_path = f"assets/brands/{brand}/{model}/sound/{mp3_files[0]}"
                print(f"✅ 成功偵測到聲音檔案: {mp3_files[0]}")
            else:
                print("⚠️ 找不到 .mp3 檔案，將設定為無聲音。")

        # ====== 6. 組裝成完美的 Flutter 對應 JSON ======
        vehicle_data = {
            "brand": brand,
            "model": model,
            "description": post.caption if post.caption else "暫無介紹",
            "author": post.owner_username,
            "price": int(price),
            "currency": "NTD",
            "spec": {
                "engine": engine,
                "horsepower": int(horsepower),
                "country": country,
                "vehicleType": vehicle_type
            },
            "media": {
                "coverPath": f"assets/brands/{brand}/{model}",
                "sourceUrl": url,
                "detailPicCount": detail_count,
                "hasSound": has_sound,
                "soundFilePath": sound_file_path
            },
            "rating": {
                "ratingTitle1": "外觀",
                "rating1": 5,
                "rating2": 5,
                "rating3": 5
            }
        }

        # 寫入本地 data.json
        json_path = os.path.join(target_base_dir, "data.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(vehicle_data, f, ensure_ascii=False, indent=4)

        print(f"\n🎉 【歸類完成】檔案已完美落地！")
        print(f"📂 專案路徑: {target_base_dir}")
        print(f"📄 結構化 JSON 範本已生成，可以直接拿去對接後端。")

    except Exception as e:
        print(f"❌ 執行過程中發生錯誤: {e}")

if __name__ == "__main__":
    run_auto_ingest()