extension SpriteArt {
    static let tilePalette: Palette = [
        "G": Colors.leaf, "g": Colors.darkLeaf, "l": Colors.paleLeaf,
        "B": Colors.brown, "b": Colors.darkBrown, "t": Colors.tan,
        "S": Colors.stone, "s": Colors.darkStone, "p": Colors.paleStone,
        "C": Colors.caveBlue, "c": Colors.deepCave, "x": Colors.crystal,
        "W": PixelColor(0xFFFFFF), "w": Colors.cloudShade, "K": Colors.sky,
        "R": PixelColor(0xB85030), "r": PixelColor(0x803018), "m": PixelColor(0xE8C8A0),
        "Y": Colors.gold, "y": Colors.darkGold, "h": Colors.paleGold, "o": Colors.orange,
        "N": Colors.outline, "L": Colors.lava, "f": Colors.lavaBright, "D": PixelColor(0x502018),
        "E": Colors.red, "Z": PixelColor(0x8090FF),
    ]

    static let tiles: [String: [String]] = [
        "tile.grass.groundTop": [
            "lGlGGlGGGlGGlGGl", "GGGGGGGGGGGGGGGG", "gGgGGgGgGGgGGgGg", "BgBBBgBBgBBBgBBB",
            "BBBBBBBBBBBBBBBB", "BBbBBBBBbBBBBBbB", "BBBBBBBBBBBBBBBB", "bBBBBbBBBBBBbBBB",
            "BBBBBBBBBBBBBBBB", "BBBBbBBBBBbBBBBB", "BBBBBBBBBBBBBBBB", "BbBBBBBBbBBBBBBb",
            "BBBBBBBBBBBBBBBB", "BBBBBBbBBBBBBbBB", "BBBBBBBBBBBBBBBB", "bBBBbBBBBbBBBBBB",
        ],
        "tile.grass.fill": [
            "BBBBBBBBBBBBBBBB", "BBbBBBBBbBBBBBbB", "BBBBBBBBBBBBBBBB", "bBBBBbBBBBBBbBBB",
            "BBBBBBBBBBBBBBBB", "BBBBbBBBBBbBBBBB", "BBBBBBBBBBBBBBBB", "BbBBBBBBbBBBBBBb",
            "BBBBBBBBBBBBBBBB", "BBBBBBbBBBBBBbBB", "BBBBBBBBBBBBBBBB", "bBBBbBBBBbBBBBBB",
            "BBBBBBBBBBBBBBBB", "BBbBBBBBbBBBBBbB", "BBBBBBBBBBBBBBBB", "BBBBBbBBBBBBbBBB",
        ],
        "tile.cave.groundTop": [
            "pSpSSpSSSpSSpSSp", "SSSSSSSSSSSSSSSS", "sSsSSsSsSSsSSsSs", "CsCCCsCCsCCCsCCC",
            "CCCCCCCCCCCCCCCC", "CCcCCCCCcCCCCCcC", "CCCCCCCCCCCCCCCC", "cCCCCcCCCCCCcCCC",
            "CCCCCCCCCCCCCCCC", "CCCCcCCCCCcCCCCC", "CCCCCCCCCCCCCCCC", "CcCCCCCCcCCCCCCc",
            "CCCCCCCCCCCCCCCC", "CCCCCCcCCCCCCcCC", "CCCCCCCCCCCCCCCC", "cCCCcCCCCcCCCCCC",
        ],
        "tile.cave.fill": [
            "CCCCCCCCCCCCCCCC", "CCcCCCCCcCCCCCcC", "CCCCCCCCCCCCCCCC", "cCCCCcCCCCCCcCCC",
            "CCCCCCCCCCCCCCCC", "CCCCcCCCCCcCCCCC", "CCCCCCCxCCCCCCCC", "CcCCCCxxxCcCCCCc",
            "CCCCCCCxCCCCCCCC", "CCCCCCcCCCCCCcCC", "CCCCCCCCCCCCCCCC", "cCCCcCCCCcCCCCCC",
            "CCCCCCCCCCCCCCCC", "CCcCCCCCcCCCCCcC", "CCCCCCCCCCCCCCCC", "CCCCCcCCCCCCcCCC",
        ],
        "tile.sky.groundTop": [
            "WWWWWWWWWWWWWWWW", "WwWWWWWwWWWWWwWW", "WWWWWWWWWWWWWWWW", "wwwwwwwwwwwwwwww",
            "pppppppppppppppp", "pSppppSppppSpppp", "pppppppppppppppp", "SpppSppppSpppSpp",
            "pppppppppppppppp", "pppppSpppppSpppp", "pppppppppppppppp", "pSppppppSppppppS",
            "pppppppppppppppp", "ppppppSppppppSpp", "pppppppppppppppp", "SpppSppppSpppppp",
        ],
        "tile.sky.fill": [
            "pppppppppppppppp", "pSppppSppppSpppp", "pppppppppppppppp", "SpppSppppSpppSpp",
            "pppppppppppppppp", "pppppSpppppSpppp", "pppppppppppppppp", "pSppppppSppppppS",
            "pppppppppppppppp", "ppppppSppppppSpp", "pppppppppppppppp", "SpppSppppSpppppp",
            "pppppppppppppppp", "pSppppSppppSpppp", "pppppppppppppppp", "pppppSppppppSppp",
        ],
        "tile.lava.groundTop": [
            "sSsSSsSSSsSSsSSs", "ssssssssssssssss", "DsDDDsDsDDsDDsDs", "DDDDDDDDDDDDDDDD",
            "DDDDDDDDDDDDDDDD", "DDcDDDDDcDDDDDcD", "DDDDDDDDDDDDDDDD", "cDDDDcDDDDDDcDDD",
            "DDDDDDDDDDDDDDDD", "DDDDcDDDDDcDDDDD", "DDDDDDDDDDDDDDDD", "DcDDDDDDcDDDDDDc",
            "DDDDDDDDDDDDDDDD", "DDDDDDcDDDDDDcDD", "DDDDDDDDDDDDDDDD", "cDDDcDDDDcDDDDDD",
        ],
        "tile.lava.fill": [
            "DDDDDDDDDDDDDDDD", "DDcDDDDDcDDDDDcD", "DDDDDDDDDDDDDDDD", "cDDDDcDDDDDDcDDD",
            "DDDDDDDDDDDDDDDD", "DDDDcDDDDDcDDDDD", "DDDDDDDDDDDDDDDD", "DcDDDDDDcDDDDDDc",
            "DDDDDDDDDDDDDDDD", "DDDDDDcDDDDDDcDD", "DDDDDDDDDDDDDDDD", "cDDDcDDDDcDDDDDD",
            "DDDDDDDDDDDDDDDD", "DDcDDDDDcDDDDDcD", "DDDDDDDDDDDDDDDD", "DDDDDcDDDDDDcDDD",
        ],
        "tile.brick": [
            "RRRRRRRmRRRRRRRm", "RRRRRRRmRRRRRRRm", "RRRRRRRmRRRRRRRm", "mmmmmmmmmmmmmmmm",
            "RRRmRRRRRRRmRRRR", "RRRmRRRRRRRmRRRR", "RRRmRRRRRRRmRRRR", "mmmmmmmmmmmmmmmm",
            "RRRRRRRmRRRRRRRm", "RRRRRRRmRRRRRRRm", "RRRRRRRmRRRRRRRm", "mmmmmmmmmmmmmmmm",
            "RRRmRRRRRRRmRRRR", "RRRmRRRRRRRmRRRR", "RRRmRRRRRRRmRRRR", "rrrrrrrrrrrrrrrr",
        ],
        "tile.question1": [
            "yYYYYYYYYYYYYYYy", "YhhYYYYYYYYYYhhY", "YhYYYYYYYYYYYYhY", "YYYYYYyyyyYYYYYY",
            "YYYYYyYYYYyYYYYY", "YYYYYyYYYYyYYYYY", "YYYYYYYYYyyYYYYY", "YYYYYYYYyyYYYYYY",
            "YYYYYYYyyYYYYYYY", "YYYYYYYyyYYYYYYY", "YYYYYYYYYYYYYYYY", "YYYYYYYyyYYYYYYY",
            "YYYYYYYyyYYYYYYY", "YhYYYYYYYYYYYYhY", "YhhYYYYYYYYYYhhY", "yyyyyyyyyyyyyyyy",
        ],
        "tile.question2": [
            "yYYYYYYYYYYYYYYy", "YhhYYYYYYYYYYhhY", "YhYYYYYYYYYYYYhY", "YYYYYYooooYYYYYY",
            "YYYYYoYYYYoYYYYY", "YYYYYoYYYYoYYYYY", "YYYYYYYYYooYYYYY", "YYYYYYYYooYYYYYY",
            "YYYYYYYooYYYYYYY", "YYYYYYYooYYYYYYY", "YYYYYYYYYYYYYYYY", "YYYYYYYooYYYYYYY",
            "YYYYYYYooYYYYYYY", "YhYYYYYYYYYYYYhY", "YhhYYYYYYYYYYhhY", "yyyyyyyyyyyyyyyy",
        ],
        "tile.question3": [
            "yhhhhhhhhhhhhhhy", "hYYhhhhhhhhhhYYh", "hYhhhhhhhhhhhhYh", "hhhhhhyyyyhhhhhh",
            "hhhhhyhhhhyhhhhh", "hhhhhyhhhhyhhhhh", "hhhhhhhhhyyhhhhh", "hhhhhhhhyyhhhhhh",
            "hhhhhhhyyhhhhhhh", "hhhhhhhyyhhhhhhh", "hhhhhhhhhhhhhhhh", "hhhhhhhyyhhhhhhh",
            "hhhhhhhyyhhhhhhh", "hYhhhhhhhhhhhhYh", "hYYhhhhhhhhhhYYh", "yyyyyyyyyyyyyyyy",
        ],
        "tile.used": [
            "bBBBBBBBBBBBBBBb", "BbbBBBBBBBBBBbbB", "BbBBBBBBBBBBBBbB", "BBBBBBBBBBBBBBBB",
            "BBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBB",
            "BBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBB",
            "BBBBBBBBBBBBBBBB", "BbBBBBBBBBBBBBbB", "BbbBBBBBBBBBBbbB", "bbbbbbbbbbbbbbbb",
        ],
        "tile.logCap": [
            "bbbbbbbbbbbbbbbb", "btttttttttttttbb", "bttBBBBBBBBBBtbb", "btBBBbbbbbbBBtbb",
            "btBBbBBBBBBbBtbb", "btBBbBBtBBBbBtbb", "btBBbBBBBBBbBtbb", "btBBBbbbbbbBBtbb",
            "bttBBBBBBBBBBtbb", "btttttttttttttbb", "bbbbbbbbbbbbbbbb", "bBBBBbBBBBBBBBbB",
            "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB",
        ],
        "tile.logBody": [
            "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB",
            "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB",
            "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB",
            "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB", "bBBBBbBBBBBBBBbB",
        ],
        "tile.cloud": [
            "....WWWW..WWW...", "..WWWWWWWWWWWWW.", ".WWWWWWWWWWWWWWW", "WWWWWWWWWWWWWWWW",
            "WWWWWWWWWWWWWWWW", "WWWWWWWWWWWWWWWW", "wWWWWWWWWWWWWWWw", "wwWWWwwWWWwwWWww",
            ".wwwwwwwwwwwwww.", "................", "................", "................",
            "................", "................", "................", "................",
        ],
        "tile.coin1": [
            "................", ".....yyyyyy.....", "....yYYYYYYy....", "...yYhhYYYYYy...",
            "...yYhYYYYYYy...", "...yYhYYYYYYy...", "...yYYYYYYYYy...", "...yYYYYYYYYy...",
            "...yYYYYYYYYy...", "...yYYYYYYYYy...", "...yYYYYYYYYy...", "...yYYYYYYYYy...",
            "...yYYYYYYYyy...", "....yYYYYYyy....", ".....yyyyyy.....", "................",
        ],
        "tile.coin2": [
            "................", "......yyyy......", ".....yYYYYy.....", "....yYhYYYYy....",
            "....yYhYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....",
            "....yYYYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....",
            "....yYYYYYyy....", ".....yYYYyy.....", "......yyyy......", "................",
        ],
        "tile.coin3": [
            "................", ".......yy.......", "......yYYy......", "......yYYy......",
            "......yYYy......", "......yYYy......", "......yYYy......", "......yYYy......",
            "......yYYy......", "......yYYy......", "......yYYy......", "......yYYy......",
            "......yYYy......", "......yYYy......", ".......yy.......", "................",
        ],
        "tile.coin4": [
            "................", "......yyyy......", ".....yYYYYy.....", "....yYYYYhYy....",
            "....yYYYYhYy....", "....yYYYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....",
            "....yYYYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....", "....yYYYYYYy....",
            "....yyYYYYYy....", ".....yyYYYy.....", "......yyyy......", "................",
        ],
        "tile.hazard.spikes": [
            "................", "................", "................", "................",
            "...p......p.....", "...p......p.....", "..pSp....pSp....", "..pSp....pSp....",
            ".pSSSp..pSSSp...", ".pSSSp..pSSSp..p", "pSSSSSppSSSSSppS", "SSSSSSSSSSSSSSSS",
            "ssssssssssssssss", "CCCCCCCCCCCCCCCC", "CCCCCCCCCCCCCCCC", "CCCCCCCCCCCCCCCC",
        ],
        "tile.hazard.lava1": [
            "................", "................", "................", "....f......f....",
            "ffffLLLLfffLLLLf", "LLLLLLLLLLLLLLLL", "LLfLLLLLLfLLLLLL", "LLLLLLLLLLLLLLLL",
            "LLLLLLfLLLLLLfLL", "LLLLLLLLLLLLLLLL", "LfLLLLLLLLfLLLLL", "LLLLLLLLLLLLLLLL",
            "LLLLfLLLLLLLLLfL", "LLLLLLLLLLLLLLLL", "LLLLLLLLfLLLLLLL", "LLLLLLLLLLLLLLLL",
        ],
        "tile.hazard.lava2": [
            "................", "................", "................", "........f.....f.",
            "LLLLffffLLLLffff", "LLLLLLLLLLLLLLLL", "LLLLLLfLLLLLLfLL", "LLLLLLLLLLLLLLLL",
            "LLfLLLLLLfLLLLLL", "LLLLLLLLLLLLLLLL", "LLLLLfLLLLLLLfLL", "LLLLLLLLLLLLLLLL",
            "fLLLLLLLLLfLLLLL", "LLLLLLLLLLLLLLLL", "LLLLfLLLLLLLLLLf", "LLLLLLLLLLLLLLLL",
        ],
        "tile.lantern": [
            "......ssss......", ".....ssssss.....", "....ssssssss....", "...ssssssssss...",
            ".....SSSSSS.....", ".....ScccccS....", ".....ScccccS....", ".....ScccccS....",
            ".....ScccccS....", ".....SSSSSS.....", "......sSSs......", "......sSSs......",
            "......sSSs......", ".....ssSSss.....", "....ssssssss....", "...ssssssssss...",
        ],
        "tile.lanternLit": [
            "......ssss......", ".....ssssss.....", "....ssssssss....", "...ssssssssss...",
            ".....SSSSSS.....", ".....SYYYYYS....", ".....SYhhYYS....", ".....SYhhYYS....",
            ".....SYYYYYS....", ".....SSSSSS.....", "......sSSs......", "......sSSs......",
            "......sSSs......", ".....ssSSss.....", "....ssssssss....", "...ssssssssss...",
        ],
        "tile.wall": [
            "ssssssssssssssss", "sSSSSSSSsSSSSSSs", "sSppSSSSsSSSppSs", "sSpSSSSSsSSSSpSs",
            "sSSSSSSSsSSSSSSs", "sSSSSSSSsSSSSSSs", "sSSSSSSSsSSSSSSs", "ssssssssssssssss",
            "sSSSsSSSSSSSsSSS", "sSSSsSppSSSSsSSS", "sSSSsSpSSSSSsSSS", "sSSSsSSSSSSSsSSS",
            "sSSSsSSSSSSSsSSS", "sSSSsSSSSSSSsSSS", "sSSSsSSSSSSSsSSS", "ssssssssssssssss",
        ],
    ]

    static let itemPalette: Palette = [
        "W": PixelColor(0xFFFFFF), "w": PixelColor(0xD8D8E0), "K": Colors.outline, "N": PixelColor(0x304030),
        "T": Colors.sand, "t": Colors.tan, "R": Colors.red, "r": Colors.darkRed, "G": Colors.leaf, "g": Colors.darkLeaf,
        "Y": Colors.gold, "y": Colors.darkGold, "h": Colors.paleGold, "S": PixelColor(0xC8D0E0), "s": PixelColor(0x707880),
        "P": Colors.pupil,
    ]

    static let items: [String: [String]] = [
        "item.onigiri": [
            "................", "................", ".......WW.......", "......WWWW......",
            ".....WWWWWW.....", "....WWWWWWWW....", "....WWWWWWWW....", "...WWWWWWWWWW...",
            "...WWWPWWPWWW...", "..WWWWWWWWWWWW..", "..WWWWWWWWWWWW..", ".WWWWNNNNNNWWWW.",
            ".WWWWNNNNNNWWWW.", "WWWWWNNNNNNWWWWW", "wwwwwNNNNNNwwwww", "................",
        ],
        "item.scroll": [
            "................", "................", "..tttttttttttt..", ".tTTTTTTTTTTTTt.",
            ".tTTTTTTTTTTTTt.", "..tTTTTTTTTTTt..", "..tTTTsssTTTTt..", "..tTTsSSSsTTTt..",
            "..tTsSSsSSsTTt..", "..tTTsSSSsTTTt..", "..tTTTsssTTTTt..", "..tTTTTTTTTTTt..",
            ".tTTTTRRRRTTTTt.", ".tTTTTTRRTTTTTt.", "..tttttttttttt..", "................",
        ],
        "item.katana": [
            "..............hh", ".............hYh", "............hYYh", "...........hYYh.",
            "..........hYYh..", ".........hYYh...", "........hYYh....", ".......hYYh.....",
            "......hYYh......", ".....hYYh.......", "....hYYh........", "...yyyh.........",
            "..yRRyy.........", ".yRRy...........", "yrry............", "rr..............",
        ],
        "item.greenScroll": [
            "................", "................", "..gggggggggggg..", ".gGGGGGGGGGGGGg.",
            ".gGGGGGGGGGGGGg.", "..gGGGGGGGGGGg..", "..gGGGhhhhGGGg..", "..gGGGhGGhGGGg..",
            "..gGGGhhhhGGGg..", "..gGGGhGGGGGGg..", "..gGGGhGGGGGGg..", "..gGGGGGGGGGGg..",
            ".gGGGGGYYGGGGGg.", ".gGGGGYYYYGGGGg.", "..gggggggggggg..", "................",
        ],
    ]

    static let smallSprites: [String: [String]] = [
        "shuriken1": ["...S....", "..sSs...", "S.sSs..S", "sSSKSSSs", "sSSKSSSs", "S..sSs.S", "...sSs..", "....S..."],
        "shuriken2": ["S......S", "sS....Ss", ".sSssSs.", "..sSKs..", "..sKSs..", ".sSssSs.", "sS....Ss", "S......S"],
        "hud.heart": [".RR..RR.", "RhRRRRRR", "RRRRRRRR", "RRRRRRRR", ".RRRRRR.", "..RRRR..", "...RR...", "........"],
        "hud.heartEmpty": [".ss..ss.", "s..ss..s", "s......s", "s......s", ".s....s.", "..s..s..", "...ss...", "........"],
        "hud.coin": ["..yyyy..", ".yYhYYy.", "yYhYYYYy", "yYYYYYYy", "yYYYYYYy", "yYYYYYYy", ".yYYYYy.", "..yyyy.."],
        "hud.lock": ["..ssss..", ".sS..Ss.", ".s....s.", "yyyyyyyy", "yYYYYYYy", "yYYyyYYy", "yYYYYYYy", "yyyyyyyy"],
        "hud.pause": ["........", ".WW..WW.", ".WW..WW.", ".WW..WW.", ".WW..WW.", ".WW..WW.", ".WW..WW.", "........"],
        "ui.arrowLeft": ["...W....", "..WW....", ".WWWWWWW", "WWWWWWWW", "WWWWWWWW", ".WWWWWWW", "..WW....", "...W...."],
        "ui.arrowRight": ["....W...", "....WW..", "WWWWWWW.", "WWWWWWWW", "WWWWWWWW", "WWWWWWW.", "....WW..", "....W..."],
        "ui.arrowUp": ["...WW...", "..WWWW..", ".WWWWWW.", "WWWWWWWW", "...WW...", "...WW...", "...WW...", "...WW..."],
        "ui.star": ["...S....", "..sSs...", "S.sSs..S", "sSSKSSSs", "sSSKSSSs", "S..sSs.S", "...sSs..", "....S..."],
        "fx.chip": ["RRRm....", "RRRm....", "mmmm....", "........", "........", "........", "........", "........"],
        "fx.puff1": ["........", "..WW....", ".WWWW.W.", ".WWWWWW.", "..WWWW..", "...WW...", "........", "........"],
        "fx.puff2": ["W......W", ".W....W.", "........", "...WW...", "........", ".W....W.", "W......W", "........"],
        "fx.spark": ["...h....", "...h....", ".hhYhh..", "..hYh...", ".hhYhh..", "...h....", "...h....", "........"],
        "fx.star": ["...Y....", "..YYY...", ".YYhYY..", "..YYY...", "...Y....", "........", "........", "........"],
    ]

    static let ninjaHead: [String] = [
        "..KKKK..", ".KKKKKK.", "RRRRRRRR", ".KSSSSK.", ".KEPEPK.", ".KKSSKK.", "..KKKK..", "........",
    ]

    static let torii: [String] = [
        "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE",
        ".EEEEEEEEEEEEEEEEEEEEEEEEEEEEEE.",
        "..rrrrrrrrrrrrrrrrrrrrrrrrrrrr..",
        "......EE................EE......",
        "......EE................EE......",
        "....EEEEEEEEEEEEEEEEEEEEEEEE....",
        "....rrrrrrrrrrrrrrrrrrrrrrrr....",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        "......EE................EE......",
        ".....ssss..............ssss.....",
        ".....ssss..............ssss.....",
    ]

    static let scenery: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        for (name, rows) in tiles {
            out[name] = PixelSprite(palette: tilePalette, rows: rows)
        }
        for (name, rows) in items {
            out[name] = PixelSprite(palette: itemPalette, rows: rows)
        }
        let small = itemPalette.merging(tilePalette) { item, _ in item }
        for (name, rows) in smallSprites {
            out[name] = PixelSprite(palette: small, rows: rows)
        }
        out["hud.ninjaHead"] = PixelSprite(palette: ninjaPalette, rows: ninjaHead)
        let gate = PixelSprite(palette: tilePalette, rows: torii)
        out["prop.torii"] = gate
        out["prop.toriiDark"] = gate.recolored { _ in Colors.darkStone }
        return out
    }()
}
