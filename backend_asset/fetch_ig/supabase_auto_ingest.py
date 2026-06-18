import os
import re
import json
import glob
import sys
import requests
from instaloader import Instaloader, Post
from supabase import create_client, Client

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

# ======== 設定 Supabase 連線資訊 ========
SUPABASE_URL = "https://fsqrgqpthqtvxfpxxxod.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzcXJncXB0aHF0dnhmcHh4eG9kIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODg3NDI4NSwiZXhwIjoyMDk0NDUwMjg1fQ.UDcksNSq5U-j90DgMiWLEPr6EM-bbc26EBGbBRzYi2Q"

# 初始化 Supabase 用戶端
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
L = Instaloader()
LOCAL_BRANDS_ROOT = r"C:\Users\user\tony\Revhub-asset\brands"


def _natural_detail_sort_key(file_path):
    match = re.search(r"p(\d+)\.jpg$", os.path.basename(file_path), re.IGNORECASE)
    return int(match.group(1)) if match else 0

def upload_to_supabase_storage(file_url, storage_path, bucket_name="car-assets"):
    """從網路下載圖片並直接串流上傳到 Supabase Storage """
    try:
        res = requests.get(file_url, stream=True)
        res.raise_for_status()
        file_data = res.content
        
        supabase.storage.from_(bucket_name).upload(
            path=storage_path,
            file=file_data,
            file_options={"content-type": "image/jpeg", "x-upsert": "true"}
        )
        
        # 取得公開瀏覽網址
        public_url = supabase.storage.from_(bucket_name).get_public_url(storage_path)
        return public_url
    except Exception as e:
        print(f"⚠️ 檔案上傳至 Storage 失敗 (Bucket: {bucket_name}, Path: {storage_path}): {e}")
        # 如果是自訂品牌 Bucket 失敗，嘗試用回預設的 car-assets 備用
        if bucket_name != "car-assets":
            print("🔄 正在嘗試使用預設 'car-assets' Bucket 進行備用上傳...")
            return upload_to_supabase_storage(file_url, storage_path, "car-assets")
        return None
    
def upload_local_file_to_storage(local_path, storage_path, content_type, bucket_name="car-assets"):
    """上傳本地檔案（如音檔、官方圖片）到 Supabase Storage"""
    try:
        if os.path.exists(local_path):
            with open(local_path, 'rb') as f:
                supabase.storage.from_(bucket_name).upload(
                    path=storage_path,
                    file=f,
                    file_options={"content-type": content_type, "x-upsert": "true"}
                )
            return supabase.storage.from_(bucket_name).get_public_url(storage_path)
        else:
            print(f"⚠️ 找不到本地檔案: {local_path}")
            return None
    except Exception as e:
        print(f"⚠️ 本地檔案上傳失敗: {e}")
        return None


def run_local_batch_ingest():
    print("=== ☁️ 本地車輛資料批次上傳系統 ===")
    json_paths = sorted(glob.glob(os.path.join(LOCAL_BRANDS_ROOT, "*", "*", "data.json")))

    if not json_paths:
        print(f"❌ 找不到任何 data.json：{LOCAL_BRANDS_ROOT}")
        return

    print(f"📦 找到 {len(json_paths)} 筆本地車輛資料，開始上傳...\n")

    for json_path in json_paths:
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                vehicle = json.load(f)

            brand = vehicle["brand"]
            model = vehicle["model"]
            vehicle_id = f"{brand}_{model}".lower().replace(" ", "_")
            vehicle_dir = os.path.dirname(json_path)
            bucket_name = "car-assets"

            cover_local_path = os.path.join(vehicle_dir, "images", "cover", "cover.jpg")
            detail_dir = os.path.join(vehicle_dir, "images", "detail")
            sound_dir = os.path.join(vehicle_dir, "sound")

            print(f"🚗 正在處理 [{brand} {model}]...")

            cover_public_url = None
            if os.path.exists(cover_local_path):
                cover_storage_path = f"{brand}/{model}/images/cover/cover.jpg"
                cover_public_url = upload_local_file_to_storage(
                    cover_local_path,
                    cover_storage_path,
                    "image/jpeg",
                    bucket_name,
                )
                if cover_public_url:
                    print("   ✅ 封面已上傳")

            detail_paths = sorted(glob.glob(os.path.join(detail_dir, "p*.jpg")), key=_natural_detail_sort_key)
            detail_upload_count = 0
            for detail_local_path in detail_paths:
                detail_filename = os.path.basename(detail_local_path)
                detail_storage_path = f"{brand}/{model}/images/detail/{detail_filename}"
                detail_public_url = upload_local_file_to_storage(
                    detail_local_path,
                    detail_storage_path,
                    "image/jpeg",
                    bucket_name,
                )
                if detail_public_url:
                    detail_upload_count += 1

            sound_public_url = None
            sound_files = [f for f in glob.glob(os.path.join(sound_dir, "*.mp3"))]
            if sound_files:
                sound_local_path = sound_files[0]
                sound_filename = os.path.basename(sound_local_path)
                sound_storage_path = f"{brand}/{model}/sound/{sound_filename}"
                sound_public_url = upload_local_file_to_storage(
                    sound_local_path,
                    sound_storage_path,
                    "audio/mpeg",
                    bucket_name,
                )
                if sound_public_url:
                    print("   ✅ 音檔已上傳")

            vehicle_data = {
                "id": vehicle_id,
                "brand": brand,
                "model": model,
                "currency": vehicle.get("currency", "NTD"),
                "price": int(vehicle.get("price", 0)),
                "has_sound": bool(sound_public_url),
                "sound_path": sound_public_url,
                "spec": {
                    "engine": vehicle.get("spec", {}).get("engine", "未知"),
                    "horsepower": int(vehicle.get("spec", {}).get("horsepower", 0)),
                    "country": vehicle.get("spec", {}).get("country", "未知"),
                    "vehicleType": vehicle.get("spec", {}).get("vehicleType", "跑車"),
                    "officialImage": cover_public_url,
                },
            }

            supabase.table("vehicles").upsert(vehicle_data).execute()
            print(f"   ✅ 已寫入 vehicles: {vehicle_id}")
            print(f"   📷 詳細圖上傳數量: {detail_upload_count}\n")

        except Exception as e:
            print(f"❌ [{json_path}] 上傳失敗: {e}\n")

    print("🎉 本地車輛資料批次上傳完成")

def run_cloud_ingest():
    print("=== ☁️ 汽車資料全自動 Supabase 雲端同步系統 (多 Bucket 擴充版) ===")
    url = input("🔗 請輸入 IG 貼文或 Reel 網址: ").strip()
    brand = input("🏢 請輸入汽車品牌 (例如 Benz): ").strip()
    model = input("🚘 請輸入車型型號 (例如 AMG_GTR): ").strip()
    
    # 標準化 Vehicle ID (也就是 Flutter 的 carID)
    vehicle_id = f"{brand}_{model}".lower().replace(" ", "_")
    # 動態決定該品牌的貼文要丟進哪個 Bucket (例如 brand="Benz" -> bucket="benz")
    brand_bucket = brand.lower().replace(" ", "_")
    
    has_sound_bool = False
    sound_url = None
    official_image_url = None
    
    try:
        # ======== 檢查 Supabase 是否已有該車款 ========
        response = supabase.table("vehicles").select("*").eq("id", vehicle_id).execute()
        
        if not response.data:
            print(f"\n✨ 雲端資料庫尚未有【{brand} {model}】！請填寫基本官方規格：")
            price = input("💰 價格 (預設 0): ").strip() or "0"
            engine = input("🔧 引擎規格(文字): ").strip() or "未知"
            horsepower = input("🐎 馬力 (預設 0): ").strip() or "0"
            country = input("🌍 製造國家: ").strip() or "未知"
            vehicle_type = input("🏁 車款類型 (例如 頂級跑車): ").strip() or "跑車"
            
            # 🖼️ 新功能：上傳官方主視覺照片
            ask_official_img = input("🖼️  請問是否有此車款的「官方照片」要上傳？(y/n): ").strip().lower()
            if ask_official_img == 'y':
                local_img_path = input("📂 請輸入本地圖片的完整路徑 (.jpg/.png): ").strip().replace('"', '')
                print("📤 正在上傳官方照片至 car-assets 專用庫...")
                storage_img_path = f"{brand}/{model}/official/cover.jpg"
                official_image_url = upload_local_file_to_storage(
                    local_img_path, storage_img_path, "image/jpeg", "car-assets"
                )
                if official_image_url:
                    print("✅ 官方照片上傳成功！")

            # 🎵 音訊檔案處理 (維持放在官方資產庫 car-assets)
            ask_sound = input("🎵 請問是否有此車款的排氣聲 .mp3 檔要上傳？(y/n): ").strip().lower()
            if ask_sound == 'y':
                local_sound_path = input("📂 請輸入本地 .mp3 檔案的完整路徑: ").strip().replace('"', '')
                print("📤 正在上傳音訊檔案至 car-assets 專用庫...")
                storage_sound_path = f"{brand}/{model}/sound/exhaust.mp3"
                sound_url = upload_local_file_to_storage(
                    local_sound_path, storage_sound_path, "audio/mpeg", "car-assets"
                )
                if sound_url:
                    has_sound_bool = True
                    print("✅ 車款音訊上傳成功！")
            
            # 寫入 vehicles 資料表 (完全對應 Flutter 的 Vehicle 與 VehicleSpec)
            vehicle_data = {
                "id": vehicle_id,
                "brand": brand,
                "model": model,
                "currency": "TWD",
                "price": int(price),
                "has_sound": has_sound_bool,
                "sound_path": sound_url,
                "spec": {
                    "engine": engine,
                    "horsepower": int(horsepower),
                    "country": country,
                    "vehicleType": vehicle_type,
                    "officialImage": official_image_url
                }
            }
            supabase.table("vehicles").insert(vehicle_data).execute()
            print(f"🎉 成功建立新車款【{brand} {model}】！")
        else:
            print(f"\n📚 【{brand} {model}】已存在於雲端資料庫。")
            existing_vehicle = response.data[0]
            has_sound_bool = existing_vehicle.get("has_sound", False)
            sound_url = existing_vehicle.get("sound_path", None)

       # ======== 擷取 IG 貼文並分流上傳至品牌專屬 Bucket ========
        match = re.search(r"/(p|reel)/([^/?]+)", url)
        if not match:
            print("❌ IG 網址解析錯誤！")
            return
        shortcode = match.group(2)
        
        print(f"📡 正在從 IG 讀取 [{shortcode}] ...")
        post = Post.from_shortcode(L.context, shortcode)
        print(f"✅ 成功讀取貼文！作者: {post.owner_username}，媒體數量: {post.mediacount}")

        print(f"🗄️ 貼文檔案將會被分類至儲存庫 Bucket: '{brand_bucket}'")

        # 同步作者大頭貼 (放到品牌 Bucket)
        avatar_src_url = post._node.get('owner', {}).get('profile_pic_url')
        print("👤 正在同步作者大頭貼...")
        storage_avatar_path = f"posts/{shortcode}/author_avatar.jpg"
        author_avatar_cloud_url = upload_to_supabase_storage(avatar_src_url, storage_avatar_path, brand_bucket)
        
        media_nodes = list(post.get_sidecar_nodes()) if post.typename == 'GraphSidecar' else [post]
        
        cover_public_url = ""
        detail_count = 0
        
        print("📤 開始將 IG 媒體同步至 Supabase Storage...")
        for idx, node in enumerate(media_nodes):
            if node.is_video:
                continue # 優先處理圖片
                
            detail_count += 1
            storage_img_path = f"posts/{shortcode}/images/detail/p{detail_count:02d}.jpg"
            
            uploaded_url = upload_to_supabase_storage(node.display_url, storage_img_path, brand_bucket)
            
            # 第一張圖做為這篇貼文的封面 coverPath
            if idx == 0 and uploaded_url:
                storage_cover_path = f"posts/{shortcode}/images/cover.jpg"
                cover_public_url = upload_to_supabase_storage(node.display_url, storage_cover_path, brand_bucket)

        # 評分自訂項目設定
        ask_rating_title = input("🏷️ 是否要自訂評分項目1 (y/n): ").strip().lower() == "y"
        if ask_rating_title:
            rating_title1 = input("🏷️  請輸入本篇貼文評分項目1 的名稱 (例如 外觀/操控): ").strip() or "外觀"
        else:
            rating_title1 = "外觀"

        print("⭐ 請為這篇貼文輸入三個評分項目的分數 (1-5)，如果不確定就直接按 Enter 預設為 5 分")
        try:
            rating1 = int(input(f"   {rating_title1} 的評分: ").strip() or "5")
            rating2 = int(input("   速度 的評分: ").strip() or "5")
            rating3 = int(input("   實用度 的評分: ").strip() or "5")
            rating1 = max(1, min(5, rating1))
            rating2 = max(1, min(5, rating2))   
            rating3 = max(1, min(5, rating3))
        except ValueError:
            print("⚠️ 評分輸入無效，已自動預設為 5 分")
            rating1 = rating2 = rating3 = 5

        # 讓管理員選擇自訂描述或使用 IG 原文
        ask_custom_desc = input("📝 是否要自訂貼文描述？(y/n): ").strip().lower() == "y"
        if ask_custom_desc:
            description = input("📝 請輸入貼文描述 (如果不輸入則使用 IG 原文): ").strip()
        else:
            description = post.caption if post.caption else ""

        # ======== 將貼文資料寫入 posts 資料表 ========
        post_data = {
            "post_id": shortcode,
            "car_id": vehicle_id,
            "author": post.owner_username,
            "author_avatar_path": author_avatar_cloud_url,
            "cover_path": cover_public_url,
            "source_url": url,
            "description": description,
            "detail_pic_count": detail_count,
            "is_video": post.is_video,
            "has_sound": has_sound_bool,
            "is_gif_cover": False,
            "sound_file_path": sound_url,
            "rating": {
                "ratingTitle1": rating_title1,
                "ratingTitle2": "速度",
                "ratingTitle3": "實用度",
                "rating1": rating1,                             
                "rating2": rating2,
                "rating3": rating3
            }
        }
        
        supabase.table("posts").insert(post_data).execute()
        print(f"\n🚀 【全自動同步完成】！")
        print(f"📊 貼文 [{shortcode}] 已完美對應 Flutter 資料結構，並已儲存至 '{brand_bucket}' 儲存庫！")

    except Exception as e:
        print(f"❌ 發生錯誤: {e}")

if __name__ == "__main__":
    if "--batch-local" in sys.argv:
        run_local_batch_ingest()
    else:
        run_cloud_ingest()