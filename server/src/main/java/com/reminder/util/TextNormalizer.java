package com.reminder.util;

import com.ibm.icu.text.Transliterator;

/**
 * 文本规范化工具，用于在存储和查询前统一用户输入的格式。
 * 处理以下字符集兼容问题：
 * 1. 繁体 → 简体（測試 → 测试）
 * 2. 全角 → 半角（１２３ → 123，Ａ → A）
 * 3. Unicode 规范化（NFD → NFC，去除组合变音符号）
 * 4. 特殊空白字符和零宽字符去除
 */
public class TextNormalizer {

    private static final Transliterator TRANSLITERATOR =
            Transliterator.getInstance("Traditional-Simplified; Fullwidth-Halfwidth; NFD; [:Nonspacing Mark:] Remove; NFC");

    /**
     * 将 email 规范化：trim → 去除特殊空白 → 小写 → 繁简/全半角/Unicode 规范化。
     */
    public static String normalizeEmail(String email) {
        if (email == null) return null;
        // 先 trim 标准空格，再去掉全角空格、零宽字符等特殊空白
        String cleaned = email.trim()
                .replaceAll("[\\u00A0\\u200B\\u200C\\u200D\\u2060\\u3000\\uFEFF]+", "")
                .toLowerCase();
        return TRANSLITERATOR.transliterate(cleaned);
    }
}
