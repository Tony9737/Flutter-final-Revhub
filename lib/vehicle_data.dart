import 'features/vehicle/domain/entities/vehicle.dart'; // 記得引入你的 model

final List<Vehicle> mockVehicles = const [
  Vehicle(
    brand: 'Benz',
    model: 'AMG GTR',
    description:
        '這是一部披上熱血 Red Bull 塗裝的 Mercedes-AMG GT R。在其霸氣的外觀下，隱藏著一具 4.0 升 V8 雙渦輪增壓引擎，能爆發出高達 585 匹的強悍馬力與 700 牛頓米的狂暴扭力，將純粹的賽道靈魂完美體現於街道之上。',
    author: 'denny_chen.0914',
    price: 10810000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: '4.0 L V8 雙渦輪增壓',
      horsepower: 585,
      country: 'Germany',
      vehicleType: '頂級跑車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Benz/AMG_GTR',
      sourceUrl:
          'https://www.instagram.com/p/DXWm2I1EgiJ/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ==',
      detailPicCount: 14,
      hasSound: true,
      soundFilePath:
          'assets/brands/Benz/AMG_GTR/sound/Angry sound of Green Hell Beast!!! Mercedes AMG GT R GTR by #GCOS.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 5,
      rating2: 4,
      rating3: 1,
    ),
  ),

  Vehicle(
    brand: 'BMW',
    model: 'M3 Touring',
    description:
        '貼文裡是一部打破常規的 BMW M3 Touring 24H。它完美保留了 M3 Touring 修長且具備實用性的旅行車身段，但骨子裡卻是直接移植了 BMW M4 GT3 賽車的狂暴基因。這不僅是一台名不虛傳的「終極好爸爸神車」，更是 BMW M 部門為了回應全球車迷與網友熱烈敲碗，將天馬行空的夢想化為現實的瘋狂之作。',
    author: 'nuerburgringls',
    price: 6260000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: 'S58 3.0 L 直六雙渦輪增壓',
      horsepower: 530,
      country: 'Germany',
      vehicleType: '好爸爸神車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/BMW/M3_Touring',
      sourceUrl: 'https://www.instagram.com/p/DV8qPl0l8gn/?img_index=1',
      detailPicCount: 6,
      hasSound: true,
      soundFilePath: 'assets/brands/BMW/M3_Touring/sound/m3_touring_sound.m4a',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 5,
      rating2: 3,
      rating3: 5,
    ),
  ),

  Vehicle(
    brand: 'Nissan',
    model: 'Z300',
    description:
        'Nissan Z300 是一款經典的運動型跑車，不僅擁有流線型的外觀設計，更具備強勁的性能表現。它搭載了一台VR30DDTT由經典的VQ系列演化而來，提供出色的加速與精準的操控回饋。在許多車媒與車主的綜合評價中，Z300 經常被讚譽為「兼具高度駕馭樂趣與日常實用性的均衡傑作」；更重要的是，相較於動輒天價的歐洲超跑，Z300 擁有相對親民的入手門檻以及較易負擔的後勤維護成本。這讓享受純粹的速度感不再是遙不可及的奢望，也使其成為眾多車迷們夢寐以求，且真正能夠付諸行動擁有的理想跑車之一。',
    author: 'larry_chen_foto',
    price: 66996,
    currency: 'USD',
    spec: VehicleSpec(
      engine: '3.0 L V6 雙渦輪增壓',
      horsepower: 420,
      country: 'Japan',
      vehicleType: '平民跑車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Nissan/Z300',
      sourceUrl:
          'https://www.instagram.com/p/DTwvO0Pjt12/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 12,
      hasSound: true,
      soundFilePath: 'assets/brands/Nissan/Z300/sound/z300_sound.m4a',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 4,
      rating2: 3,
      rating3: 2,
    ),
  ),

  Vehicle(
    brand: 'BMW',
    model: 'M4',
    description:
        'BMW M4 絕對是當代高性能雙門跑車的指標性代表。它捨棄了內斂，換上極具侵略性的寬體肌肉線條與極高辨識度的巨型雙腎水箱護罩，強烈暗示著其不凡的實力。它的動力心臟搭載了被譽為當代名機的 S58 3.0 升直列六缸雙渦輪增壓引擎，不僅能爆發出令人震懾的強悍動力，搭配 M 部門神經質般精準的底盤調校與強大的電控系統，為駕駛帶來刀切豆腐般的犀利轉向與極致的貼背快感。',
    author: 'eternamotorworks',
    price: 6220000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: 'S58 3.0 L 直六雙渦輪增壓',
      horsepower: 523,
      country: 'Germany',
      vehicleType: '高性能豪華雙門跑車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/BMW/M4',
      sourceUrl:
          'https://www.instagram.com/p/Cwndl3Op9oz/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 9,
      hasSound: true,
      soundFilePath: 'assets/brands/BMW/M4/sound/m4_sound.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 4,
      rating2: 4,
      rating3: 3,
    ),
  ),

  Vehicle(
    brand: 'Porsche',
    model: '911 GT3 RS',
    description:
        'Porsche 911 GT3 RS 是為賽道而生的終極信仰，全車設計皆為了在賽道上削去那零點一秒。它傲視群雄地堅持 4.0 升水平對臥六缸自然進氣引擎，紅線轉速直衝 9,000 轉，不僅爆發超過 500 匹馬力，更擁有神經反射般的零遲滯動力回饋。外觀武裝了誇張的 DRS 主動式減阻系統與天鵝頸尾翼，搭配雙 A 臂懸吊與極致輕量化工程，讓它具備如手術刀般的精準指向性。這不是一台日常巡航的跑車，而是將高轉速聲浪與極端空氣動力學完美結合、讓本格派玩家為之瘋狂的賽道機器。',
    author: 'porsche',
    price: 13200000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: '4.0 L 水平對臥六缸 NA',
      horsepower: 525,
      country: 'Germany',
      vehicleType: '賽道機器',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Porsche/911 GT3 RS',
      sourceUrl:
          'https://www.instagram.com/p/DGQBED4sal4/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ==',
      detailPicCount: 10,
      hasSound: true,
      soundFilePath:
          'assets/brands/Porsche/911 GT3 RS/sound/911-gt3-rs-enginesound.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 5,
      rating2: 5,
      rating3: 1,
    ),
  ),

  Vehicle(
    brand: 'Porsche',
    model: 'Cayman GT4 RS',
    description:
        'Porsche 718 Cayman GT4 RS 是一款將中置引擎潛力發揮到淋漓盡致的狂暴機器，也是 RS 家族中最具感官衝擊的成員。它直接移植了 911 GT3 的 4.0 升水平對臥六缸自然進氣引擎，具備 500 匹馬力與 9,000 轉的驚人極限，搭配齒比緊密的 PDK 雙離合器自手排變速箱，0-100 km/h 僅需 3.4 秒。最令人血脈賁張的特點在於其側窗位置的進氣口，讓高亢的進氣聲浪直接在駕駛耳後轟鳴；結合天鵝頸式尾翼與 Weissach 套件的極致輕量化工程，GT4 RS 以無與倫比的靈活性與純粹的機械回饋，重新定義了中置跑車的操駕巔峰。',
    author: 'loweclassics',
    price: 7940000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: '4.0 L 水平對臥六缸 NA',
      horsepower: 500,
      country: 'Germany',
      vehicleType: '賽道機器',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Porsche/Cayman GT4 RS',
      sourceUrl:
          'https://www.instagram.com/p/DOtvFjHDNHY/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 10,
      hasSound: true,
      soundFilePath:
          'assets/brands/Porsche/Cayman GT4 RS/sound/718-gt4-rs-engine-sound.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 4,
      rating2: 3,
      rating3: 2,
    ),
  ),

  Vehicle(
    brand: 'Audi',
    model: 'RS6 Avant',
    description:
        'Audi RS6 Avant 是一款將性能與實用性完美結合的高性能旅行車。它搭載了一台 4.0 升 V8 雙渦輪增壓引擎，能爆發出超過 600 匹的強悍馬力與 800 牛頓米的驚人扭力，讓這台旅行車在加速時展現出令人震撼的動力表現。RS6 Avant 不僅擁有寬敞的內部空間和豪華的配備，還配備了 quattro 全時四輪驅動系統和先進的懸吊技術，提供卓越的操控性和穩定性。無論是在高速公路上還是彎道中，RS6 Avant 都能帶來極致的駕駛樂趣，是一款真正兼具性能與實用性的夢幻旅行車。',
    author: 'srs_swissrichstreets',
    price: 7400000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: '4.0 L V8 雙渦輪增壓',
      horsepower: 621,
      country: 'Germany',
      vehicleType: '高性能旅行車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Audi/RS6 Avant',
      sourceUrl:
          'https://www.instagram.com/p/C_6Be3Ou_6s/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 10,
      hasSound: true,
      soundFilePath: 'assets/brands/Audi/RS6 Avant/sound/RS6_sound.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 5,
      rating2: 3,
      rating3: 5,
    ),
  ),

  Vehicle(
    brand: 'Nissan',
    model: 'R34',
    description:
        'Nissan Skyline GT-R R34 是一款經典的日本性能車，擁有獨特的外觀設計和強大的性能表現。它搭載了一台 RB26DETT 2.6 升直列六缸雙渦輪增壓引擎，能爆發出超過 280 匹的馬力和 392 牛頓米的扭力，配合先進的 ATTESA E-TS 全時四輪驅動系統和多連桿懸吊，提供卓越的操控性和穩定性。R34 不僅在賽道上表現出色，也因其在電影《頭文字D》和《玩命關頭》系列中的亮相而成為車迷心中的傳奇，是一款真正經典且具有歷史意義的性能車。',
    author: 'aussietookem',
    price: 1500000,
    currency: 'USD',
    spec: VehicleSpec(
      engine: 'RB26 2.6 L 直六雙渦輪增壓',
      horsepower: 280,
      country: 'Japan',
      vehicleType: '經典性能跑車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Nissan/R34',
      sourceUrl:
          'https://www.instagram.com/p/DRzwuQRkbhG/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 12,
      hasSound: true,
      soundFilePath: 'assets/brands/Nissan/R34/sound/r34.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 5,
      rating2: 2,
      rating3: 3,
    ),
  ),

  Vehicle(
    brand: 'Toyota',
    model: 'GR Yaris',
    description:
        'TOYOTA GR Yaris 是由賽事部門 Gazoo Racing 為拉力賽而生的純種鋼砲，在車迷間擁有「暴力鴨」的響亮稱號。它搭載了代號 G16E-GTS 的 1.6 升三缸渦輪增壓引擎，擁有突破 260 匹馬力的強悍輸出，是目前全球最強的三缸量產引擎之一。為了追求極致性能，它採用專屬的三門寬體車身與碳纖維車頂，並配備了強大的 GR-FOUR 電子控制四輪傳動系統，讓駕駛能在不同模式下自由分配前後動力輸出。這台車不僅具備靈活刁鑽的短軸距優勢，更在操控感中注入了 WRC 拉力賽的狂放基因，以純粹的機械感與爆發力，證明了小鋼砲也能擁有足以令超跑側目的強悍戰鬥力。',
    author: 'srs_swissrichstreets',
    price: 1950000,
    currency: 'NTD',
    spec: VehicleSpec(
      engine: '1.6 L I3 Twin Turbo',
      horsepower: 260,
      country: 'Japan',
      vehicleType: '高性能小鋼砲',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Toyota/GR Yaris',
      sourceUrl:
          'https://www.instagram.com/p/DOYz36DiA_5/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 9,
      hasSound: true,
      soundFilePath: 'assets/brands/Toyota/GR Yaris/sound/gr_yaris.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 3,
      rating2: 4,
      rating3: 3,
    ),
  ),

  Vehicle(
    brand: 'Toyota',
    model: 'GR GT',
    description:
        'Toyota GR GT 是一款將賽道基因推向極致的旗艦頂級跑車，不僅代表著品牌對高性能的極致追求，更承襲了其「雙胞胎」版本——GR GT3 Concept 賽車的純血設計精髓。這台車從開發之初就採取「賽車優先」的逆向研發邏輯，打破過往將道路用車改裝成賽車的傳統，確保量產車型也能擁有最完美的配重與空力幾何。它搭載了極具侵略性的長車頭設計、大型天鵝頸尾翼與充滿視覺張力的寬體空力套件，展現出足以與歐系超跑抗衡的霸氣。作為一台與 GT3 賽事版本同步開發的街道機器，GR GT 透過極致輕量化與先進的動力懸吊調校，將專業賽車的極限操控感完美移植至日常道路，成為車迷眼中最具競技魂的終極座駕。',
    author: 'ndmaho',
    price: 220000,
    currency: 'USD',
    spec: VehicleSpec(
      engine: '4.0 L V8 雙渦輪增壓引擎',
      horsepower: 650,
      country: 'Japan',
      vehicleType: '旗艦頂級跑車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Toyota/GR GT',
      sourceUrl:
          'https://www.instagram.com/p/DTnEZnGkpdb/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 6,
      hasSound: true,
      soundFilePath: 'assets/brands/Toyota/GR GT/sound/GR_GT.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 5,
      rating2: 4,
      rating3: 1,
    ),
  ),

  Vehicle(
    brand: 'Ford',
    model: 'Mustang',
    description:
        'Ford Mustang GTD 是一款打破傳統美式肌肉車定義的極致性能怪獸，其開發初衷極其明確：征服素有「綠色地獄」之稱的紐柏林賽道。這台車搭載 5.2 升 V8 機械增壓引擎，擁有高達 815 匹馬力的狂暴輸出，並配備主動式空力套件與專屬推桿式懸吊系統。它在紐柏林北環賽道跑出了 6 分 52 秒 072 的驚人圈速，不僅成為史上最快的美國量產車，成績更直接叫板 Porsche 911 GT3 RS 的標竿紀錄。GTD 本質上是與 Mustang GT3 賽車版本同步開發的「雙胞胎」道路版，透過極致輕量化與純種競技底盤，將美式力量與歐式精準操控完美融合，是一台真正為了在全球頂尖賽道奪秒而生的超級跑車。',
    author: 'villafordoc',
    price: 325000,
    currency: 'USD',
    spec: VehicleSpec(
      engine: '5.2 L V8 機械增壓',
      horsepower: 815,
      country: 'USA',
      vehicleType: '美式肌肉車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Ford/Mustang',
      sourceUrl:
          'https://www.instagram.com/p/DSoEhEAD125/?utm_source=ig_web_copy_link',
      detailPicCount: 12,
      hasSound: true,
      soundFilePath: 'assets/brands/Ford/Mustang/sound/Mustang GTD Sounds.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '外觀',
      rating1: 4,
      rating2: 3,
      rating3: 2,
    ),
  ),

  Vehicle(
    brand: 'Mazda',
    model: 'Miata NA',
    description:
        'Mazda MX-5 Miata 是全球最暢銷的傳奇雙座敞篷跑車，自 1989 年問世以來，始終堅持「人馬一体」的極致操控哲學。它不追求數據上的狂暴動力，而是透過 2.0 升自然進氣引擎與極輕量化的車身比例，創造出最純粹、直覺的駕駛樂趣。不到一公噸的輕巧車重，搭配後輪驅動設定與精準的 50:50 前後配重，讓它在彎道中展現出猶如身體延伸般的靈活反應。無論是手感極佳的六速手排變速箱，還是只需數秒即可完成操作的手動軟篷，每一處細節都回歸到最原始的機械美感。對於愛車人而言，Miata 不僅是一台代步工具，更是一種生活態度的象徵，證明了不需要天價預算，也能擁有讓嘴角不自覺上揚的頂級操駕享受。',
    author: 'noki_carphoto',
    price: 15000,
    currency: 'USD',
    spec: VehicleSpec(
      engine: '2.0 L 自然進氣',
      horsepower: 155,
      country: 'Japan',
      vehicleType: '平民跑車',
    ),
    media: VehicleMedia(
      coverPath: 'assets/brands/Mazda/Miata NA',
      sourceUrl:
          'https://www.instagram.com/p/DXaPRBllJGx/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==',
      detailPicCount: 13,
      hasSound: true,
      soundFilePath: 'assets/brands/Mazda/Miata NA/sound/Mazda Miata NA.mp3',
    ),
    rating: VehicleRating(
      ratingTitle1: '可愛度',
      rating1: 5,
      rating2: 2,
      rating3: 2,
    ),
  ),
  // Vehicle(brand: 'Chevrolet', model: 'Corvette C8 Z06'),
  // Vehicle(brand: 'Subaru', model: 'BRZ'),
  // Vehicle(brand: 'Subaru', model: 'Impreza'),
  // Vehicle(brand: 'Mitsubishi', model: 'EVO VIII'),
  // Vehicle(brand: 'Honda', model: 'Civic Type R FL5'),
  // Vehicle(brand: 'Honda', model: 'S2000'),
  // Vehicle(brand: 'Dodge', model: 'Viper GTS'),
  // Vehicle(brand: 'Dodge', model: 'Challenger'),
  // Vehicle(brand: 'Mazda', model: 'Miata ND'),
  // Vehicle(brand: 'Chevrolet', model: 'Camaro'),
  // Vehicle(brand: 'Benz', model: 'SLS'),
];
