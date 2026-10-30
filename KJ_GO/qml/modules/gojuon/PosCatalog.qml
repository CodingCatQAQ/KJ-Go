pragma Singleton
import QtQuick

QtObject {
    readonly property var kinds: [
        {
            label: "体词",
            ja: "名词、代词、数词",
            ko: "名词、代词、数词、依存名词",
            note: "所有可以独立充当主语/宾语、表达具体/抽象事物概念的词汇，无需接谓语就能独立在句子中充当核心成分。"
        },
        {
            label: "动词",
            ja: "动作动词、自动词/他动词、补助动词",
            ko: "动作动词、自动词/他动词、补助动词",
            note: "表示动作、行为、变化的词汇，两门语言均有统一的词干活用规则。"
        },
        {
            label: "形容词",
            ja: "イ形容词",
            ko: "状态形容词、补助形容词",
            note: "直接表达事物性质、状态、主观感受的词汇，两门语言均可直接变形充当谓语。"
        },
        {
            label: "副词",
            ja: "普通副词、拟声拟态词、部分接续副词",
            ko: "普通副词、连接副词、拟声拟态词",
            note: "用来修饰动词、形容词或整个句子，本身不能直接修饰名词。"
        },
        {
            label: "助词",
            ja: "格助词、提示助词、接续助词、副助词",
            ko: "格助词、补助助词、接续助词",
            note: "黏着在体词或谓语后面，用来标记语法关系、补充语义，是两门黏着语最核心的功能类词性。"
        },
        {
            label: "冠形词",
            ja: "原生连体词、ナ形容词连体形、动词连体形",
            ko: "原生冠形词、谓词变形后的冠形形态",
            note: "唯一功能就是直接修饰限定后面接的名词，不能独立充当句子其他成分。"
        },
        {
            label: "语尾/助动词",
            ja: "助动词、句末终助词",
            ko: "语末语尾、连接语尾、转类语尾",
            note: "附着在谓语词干末尾，用来承载时态、敬语级别、语气、句式功能的黏着成分。"
        },
        {
            label: "其他",
            ja: "感叹词、接头词、接尾词、特殊固定惯用语",
            ko: "感叹词、前缀、后缀、特殊固定惯用型",
            note: "所有无法归入前面7类的零散特殊词汇、语素，作为兜底分类。"
        }
    ]

    function find(label) {
        if (!label)
            return null
        for (var i = 0; i < kinds.length; ++i) {
            if (kinds[i].label === label)
                return kinds[i]
        }
        return null
    }

    function labelsOf(written) {
        var raw = []
        if (written === undefined || written === null || written === "")
            raw = []
        else if (typeof written === "string")
            raw = [written]
        else
            raw = written
        var ordered = []
        for (var i = 0; i < kinds.length; ++i) {
            var label = kinds[i].label
            if (label === "其他")
                continue
            for (var j = 0; j < raw.length; ++j) {
                if (raw[j] === label) {
                    ordered.push(label)
                    break
                }
            }
        }
        if (ordered.length === 0)
            ordered.push("其他")
        return ordered
    }

    function textOf(written) {
        return labelsOf(written).join(" · ")
    }

    function cover(kind, language) {
        if (!kind)
            return ""
        return language === "ja" ? kind.ja : kind.ko
    }
}
