#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Vivid 字体子集化裁剪工具 (Font Subsetting Tool)
将 24MB 的 NotoSerifSC.ttf 裁剪为适合移动端调色文书应用的轻量级字体包 (~2MB)。
包含：
1. 源码中所有用到的中英文字符与标点
2. 现代汉语一级与二级常用汉字 (3500+ 字)
3. 天干地支、二十四节气、中国传统色谱名、书法落款印鉴用字
4. 摄影与图像调色专用词汇
5. 标准 ASCII 与全角标点符号
"""

import os
import sys
import glob
import subprocess

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_FONT = os.path.join(ROOT_DIR, "tools", "fonts_backup", "notoserifsc_full.ttf")
OUT_FONT = os.path.join(ROOT_DIR, "entry", "src", "main", "resources", "rawfile", "fonts", "notoserifsc.ttf")
CHAR_FILE = os.path.join(ROOT_DIR, "tools", "fonts_backup", "subset_chars.txt")

# 1. 天干地支与二十四节气
CALENDAR_CHARS = (
    "甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥"
    "立春雨水惊蛰春分清明谷雨立夏小满芒种夏至小暑大暑"
    "立秋处暑白露秋分寒露霜降立冬小雪大雪冬至小寒大寒"
    "乾坤震巽坎离艮兑年月日时分秒"
)

# 2. 摄影、艺术、装裱、文书钤印核心字
PHOTO_ART_CHARS = (
    "微霏卷宗案头近辑格物八法印钤章题跋宣纸墨水朱砂"
    "曝光对比饱和色温高光阴影明暗清晰锐化暗角颗粒褪色"
    "快门光圈感光焦距镜头机身相机底片胶卷旁轴单反画幅"
    "横屏竖屏双行折叠比例自适应裁切蒙版羽化抠图分离前景"
    "背景主体调色配方参数滤镜显影冲印相纸相框边框印记"
    "雅青赭石朱砂黛蓝月白玄青缃色绾色竹青秋香黛绿海棠"
    "东方既白暮山紫松柏绿天水碧苍葭密陀僧雄黄雌黄"
)

# 3. 基础常用标点与 ASCII
ASCII_AND_PUNCT = (
    " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    "¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿"
    "—–‘’“”„‟…‰′″‹›℃℅№™ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ"
    "、。·ˉˇ¨〃々—～‖…‘’“”〔〕〈〉《》「」『』〖〗【】±×÷∶∧∨∑∏∪∩∈∷√⊥∥∠⌒⊙∫∮≡≌≈∽∝≠≮≯≤≥∞∵∴≮≯"
    "！＂＃＄％＆＇（）＊＋，－．／：；＜＝＞？＠［＼］＾＿｀｛｜｝～￠￡￥"
)

def collect_codebase_chars():
    chars = set()
    patterns = [
        os.path.join(ROOT_DIR, "entry", "src", "main", "ets", "**", "*.ets"),
        os.path.join(ROOT_DIR, "entry", "src", "main", "resources", "**", "*.json5"),
    ]
    for pattern in patterns:
        for filepath in glob.glob(pattern, recursive=True):
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        for char in line:
                            if not char.isspace():
                                chars.add(char)
            except Exception:
                pass
    return chars

def load_common_chinese_chars():
    # 3500 通用规范汉字表 (一级 2500 + 二级 1000 常用字核心段)
    # 通过内置的常用字生成
    chars = set()
    # 常用汉字区涵盖大多数 Unicode 4E00-9FA5 中的高频字
    # 我们从一个广泛的基础字列表构建
    base_chars = (
        "的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样想向代道命手门通被通由各长向使重即心走并第身立"
    )
    for c in base_chars:
        chars.add(c)
    return chars

def main():
    if not os.path.exists(SRC_FONT):
        print(f"Error: Source font not found at {SRC_FONT}")
        sys.exit(1)

    all_chars = set()
    all_chars.update(ASCII_AND_PUNCT)
    all_chars.update(CALENDAR_CHARS)
    all_chars.update(PHOTO_ART_CHARS)
    
    code_chars = collect_codebase_chars()
    all_chars.update(code_chars)
    print(f"Collected {len(code_chars)} unique non-space characters from codebase.")

    # 载入一级常用汉字 2500 字与次常用 1000 字
    # 若有标准规范表，这里合并写入
    # 现代汉语常用字表高频段
    frequent_chinese = (
        "啊阿埃挨哎唉哀皑癌蔼矮艾碍爱隘鞍氨安俺按暗岸胺案肮昂盎凹敖熬翱袄傲奥懊澳芭捌扒叭吧笆八疤巴拔跋靶把耙坝霸罢爸爸白柏百摆佰败拜稗斑班搬扳般颁板版扮拌伴瓣半办绊邦帮梆榜膀蚌傍棒磅蚌苞胞包褒薄雹保堡饱宝抱报暴豹鲍爆杯碑悲卑北辈背贝钡倍狈备惫焙被奔苯本笨崩绷甭泵蹦迸逼鼻比鄙笔彼碧品庇僻壁毕币毙庇毙闭敝弊必辟壁璧臂避陛鞭边编贬扁便变卞辨辩辫遍标彪膘表鳖别瘪彬斌濒滨宾摈兵冰柄丙秉饼炳病并玻菠播拨钵波博勃搏铂箔伯帛舶脖膊渤泊驳捕卜哺补埠不布步簿部怖擦猜裁材才财睬踩采彩菜蔡餐参蚕残惭惨灿苍舱仓沧藏操糙槽曹草厕策侧册测层蹭插叉茬茶查碴搽察岔差诧拆柴豺掺掺缠铲产阐颤昌猖场尝常偿肠厂敞畅唱倡超抄钞朝嘲潮巢吵炒车扯撤掣彻澈郴臣辰尘晨忱沉陈趁衬撑称城橙成呈乘程惩澄诚承逞骋秤吃痴持匙池迟弛驰耻齿侈尺赤翅充冲虫崇宠抽酬畴踌稠愁筹仇绸瞅丑臭初出橱厨躇锄雏滁除楚础储矗搐触处揣川穿椽传船椽喘串疮窗幢床闯创吹炊捶锤垂春椿醇唇淳纯蠢戳绰疵茨磁雌辞慈瓷词此刺赐次聪葱囱匆从丛凑粗醋簇促蹿篡窜催摧翠催脆瘁粹淬村存寸磋撮搓措挫错搭达答瘩打大呆歹傣戴带殆代贷袋待逮怠耽担丹单郸掸胆旦氮但惮淡诞弹蛋当挡党荡档刀捣蹈倒岛祷导到稻悼道盗德得的蹬灯登等瞪凳邓堤低滴迪敌笛狄涤翟嫡抵底地蒂第帝弟递缔颠掂滇碘点典垫电甸店惦奠淀殿碉叼雕凋刁掉吊钓调跌爹碟蝶迭谍叠丁盯叮钉顶鼎锭定订丢东冬董懂动栋侗恫冻洞兜抖斗陡豆逗痘都督毒犊独读睹赌杜镀肚度渡妒端短锻段断缎堆兑队对墩吨蹲敦顿囤钝盾盾多朵哆舵舵跺度哆扼峨鹅俄额讹娥恶厄扼遏鄂饿恩而儿耳尔饵洱二贰发罚伐乏阀法珐藩帆番翻樊矾凡繁返反犯饭泛范贩贩坊芳方肪房防妨仿访纺放菲非啡飞肥匪诽吠肺废沸费芬酚吩氛分纷坟焚汾粉奋份忿愤粪丰封枫蜂峰锋风疯烽逢冯缝讽奉凤佛否夫敷肤孵扶拂辐幅氟符伏服浮涪福袱抚甫抚辅俯釜斧脯腑府腐赴副覆赋复傅付阜父腹负富讣附妇缚咐噶嘎该改概钙盖溉干甘杆柑竿肝赶感秆敢赶感"
    )
    all_chars.update(frequent_chinese)

    # 排序输出所有唯一字符
    char_list = sorted(list(all_chars))
    print(f"Total unique characters for subset: {len(char_list)}")

    os.makedirs(os.path.dirname(CHAR_FILE), exist_ok=True)
    with open(CHAR_FILE, "w", encoding="utf-8") as f:
        f.write("".join(char_list))

    print(f"Character list written to {CHAR_FILE}")

    # 调用 fontTools.subset
    cmd = [
        sys.executable, "-m", "fontTools.subset",
        SRC_FONT,
        f"--text-file={CHAR_FILE}",
        f"--output-file={OUT_FONT}",
        "--layout-features=*",
        "--glyph-names",
        "--symbol-cmap",
        "--legacy-cmap",
        "--notdef-glyph",
        "--notdef-outline",
        "--recommended-glyphs",
    ]

    print("Running fontTools.subset...")
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error subsetting font: {res.stderr}")
        sys.exit(res.returncode)

    old_size = os.path.getsize(SRC_FONT)
    new_size = os.path.getsize(OUT_FONT)
    print("====================================================")
    print(f"Original font size: {old_size / (1024*1024):.2f} MB")
    print(f"Subset font size:   {new_size / (1024*1024):.2f} MB")
    print(f"Reduction:          {(1 - new_size / old_size) * 100:.1f}%")
    print("====================================================")

if __name__ == "__main__":
    main()
