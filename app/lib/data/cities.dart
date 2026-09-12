/// 出生地——按省级行政区列出(4 直辖市 + 23 省 + 5 自治区 + 2 特别行政区 +
/// 台湾地区,共 34 个),用省会/主要城市的经纬度代表全省,供真太阳时换算用。
///
/// 只做到省级是有意简化:多数用户说不清具体到哪个县市的经度,省级坐标已经
/// 比"完全不管经度、只用北京时间"精确得多,又不必让用户理解"经度"这个概念。
library;

class City {
  const City(this.name, this.en, this.longitude, this.latitude, {this.timezone = 8.0});

  /// 中文名(简体;繁体由 S2T 转换),也是档案里持久化的键。
  final String name;
  final String en;
  final double longitude;
  final double latitude;
  final double timezone;
}

/// 按中文名查英文;查不到原样返回(老档案里可能存着不在表里的名字)。
String cityEnglish(String zhName) => cities.where((c) => c.name == zhName).map((c) => c.en).firstOrNull ?? zhName;

const List<City> cities = [
  // ---- 直辖市 ----
  City('北京', 'Beijing', 116.41, 39.90),
  City('上海', 'Shanghai', 121.47, 31.23),
  City('天津', 'Tianjin', 117.20, 39.08),
  City('重庆', 'Chongqing', 106.55, 29.56),
  // ---- 省(以省会经纬度代表) ----
  City('河北', 'Hebei', 114.51, 38.04),
  City('山西', 'Shanxi', 112.55, 37.87),
  City('辽宁', 'Liaoning', 123.43, 41.80),
  City('吉林', 'Jilin', 125.32, 43.82),
  City('黑龙江', 'Heilongjiang', 126.53, 45.80),
  City('江苏', 'Jiangsu', 118.80, 32.06),
  City('浙江', 'Zhejiang', 120.15, 30.27),
  City('安徽', 'Anhui', 117.23, 31.82),
  City('福建', 'Fujian', 119.30, 26.08),
  City('江西', 'Jiangxi', 115.86, 28.68),
  City('山东', 'Shandong', 117.00, 36.65),
  City('河南', 'Henan', 113.63, 34.75),
  City('湖北', 'Hubei', 114.31, 30.59),
  City('湖南', 'Hunan', 112.94, 28.23),
  City('广东', 'Guangdong', 113.26, 23.13),
  City('海南', 'Hainan', 110.35, 20.02),
  City('四川', 'Sichuan', 104.07, 30.57),
  City('贵州', 'Guizhou', 106.63, 26.65),
  City('云南', 'Yunnan', 102.83, 25.04),
  City('陕西', 'Shaanxi', 108.94, 34.34),
  City('甘肃', 'Gansu', 103.83, 36.06),
  City('青海', 'Qinghai', 101.78, 36.62),
  // ---- 自治区 ----
  City('内蒙古', 'Inner Mongolia', 111.75, 40.84),
  City('广西', 'Guangxi', 108.37, 22.82),
  City('西藏', 'Tibet', 91.11, 29.65),
  City('宁夏', 'Ningxia', 106.23, 38.49),
  City('新疆', 'Xinjiang', 87.62, 43.83),
  // ---- 特别行政区 / 台湾地区 ----
  City('香港', 'Hong Kong', 114.17, 22.32),
  City('澳门', 'Macau', 113.54, 22.19),
  City('台湾', 'Taiwan', 121.56, 25.03),
  // ---- 常见海外出生地(城市级,供华人华侨用) ----
  City('新加坡', 'Singapore', 103.82, 1.35),
  City('吉隆坡', 'Kuala Lumpur', 101.69, 3.14),
  City('东京', 'Tokyo', 139.69, 35.69, timezone: 9),
  City('首尔', 'Seoul', 126.98, 37.57, timezone: 9),
  City('悉尼', 'Sydney', 151.21, -33.87, timezone: 10),
  City('伦敦', 'London', -0.13, 51.51, timezone: 0),
  City('巴黎', 'Paris', 2.35, 48.86, timezone: 1),
  City('纽约', 'New York', -74.01, 40.71, timezone: -5),
  City('洛杉矶', 'Los Angeles', -118.24, 34.05, timezone: -8),
  City('温哥华', 'Vancouver', -123.12, 49.28, timezone: -8),
  City('多伦多', 'Toronto', -79.38, 43.65, timezone: -5),
];
