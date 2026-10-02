"""
Localized notification templates for en, gu, hi.
Spec Section 7 & Rule 7: Every user-visible string comes from i18n files (en, gu, hi).
Push text comes from server templates by the user's language.
"""

from typing import Any

TEMPLATES: dict[str, dict[str, dict[str, str]]] = {
    "TOKEN_CONFIRMED": {
        "en": {
            "title": "Token Confirmed",
            "body": "Your token {display_code} is confirmed. Estimated wait: {wait_minutes} min.",
        },
        "gu": {
            "title": "ટોકન કન્ફર્મ થયો",
            "body": "તમારો ટોકન {display_code} કન્ફર્મ થયો છે. અંદાજિત રાહ: {wait_minutes} મિનિટ.",
        },
        "hi": {
            "title": "टोकन कन्फर्म हुआ",
            "body": "आपका टोकन {display_code} कन्फर्म हो गया है। अनुमानित प्रतीक्षा: {wait_minutes} मिनट।",
        },
    },
    "GET_READY": {
        "en": {
            "title": "Get Ready",
            "body": "Get ready! Your token {display_code} will be called in approximately {wait_minutes} min.",
        },
        "gu": {
            "title": "તૈયાર રહો",
            "body": "તૈયાર રહો! તમારો ટોકન {display_code} આશરે {wait_minutes} મિનિટમાં બોલાવવામાં આવશે.",
        },
        "hi": {
            "title": "तैयार रहें",
            "body": "तैयार रहें! आपका टोकन {display_code} लगभग {wait_minutes} मिनट में बुलाया जाएगा।",
        },
    },
    "LEAVE_NOW": {
        "en": {
            "title": "Time to Leave",
            "body": "Time to leave! Your turn for token {display_code} is approaching.",
        },
        "gu": {
            "title": "નીકળવાનો સમય",
            "body": "નીકળવાનો સમય થઈ ગયો છે! ટોકન {display_code} માટે તમારો વારો નજીક છે.",
        },
        "hi": {
            "title": "निकलने का समय",
            "body": "निकलने का समय हो गया है! टोकन {display_code} के लिए आपकी बारी पास आ रही है।",
        },
    },
    "YOUR_TURN": {
        "en": {
            "title": "Your Turn",
            "body": "Your turn! Please proceed to Counter {counter_label} for token {display_code}.",
        },
        "gu": {
            "title": "તમારો વારો",
            "body": "તમારો વારો! કૃપા કરીને ટોકન {display_code} માટે કાઉન્ટર {counter_label} પર જાઓ.",
        },
        "hi": {
            "title": "आपकी बारी",
            "body": "आपकी बारी! कृपया टोकन {display_code} के लिए काउंटर {counter_label} पर जाएं।",
        },
    },
    "ETA_CHANGED": {
        "en": {
            "title": "Wait Time Updated",
            "body": "Wait time updated for {display_code}: now {wait_minutes} min.",
        },
        "gu": {
            "title": "સમય બદલાયો",
            "body": "{display_code} માટે રાહ જોવાનો સમય બદલાયો: હવે {wait_minutes} મિનિટ.",
        },
        "hi": {
            "title": "प्रतीक्षा समय बदला",
            "body": "{display_code} के लिए प्रतीक्षा समय बदला गया: अब {wait_minutes} मिनट।",
        },
    },
    "NO_SHOW_WARNING": {
        "en": {
            "title": "Grace Period Warning",
            "body": "Hurry! Only 2 minutes remaining to report to counter for token {display_code}.",
        },
        "gu": {
            "title": "ચેતવણી",
            "body": "ઉતાવળ કરો! ટોકન {display_code} માટે કાઉન્ટર પર રિપોર્ટ કરવા માત્ર 2 મિનિટ બાકી છે.",
        },
        "hi": {
            "title": "चेतावनी",
            "body": "जल्दी करें! टोकन {display_code} के लिए काउंटर पर रिपोर्ट करने के लिए केवल 2 मिनट बचे हैं।",
        },
    },
    "REQUEUED": {
        "en": {
            "title": "Token Requeued",
            "body": "You missed your call. Token {display_code} has been placed back in queue.",
        },
        "gu": {
            "title": "ટોકન ફરીથી કતારમાં",
            "body": "તમે તમારો વારો ચૂકી ગયા. ટોકન {display_code} ફરીથી કતારમાં મૂકવામાં આવ્યો છે.",
        },
        "hi": {
            "title": "टोकन पुनः कतार में",
            "body": "आप अपनी बारी चूक गए। टोकन {display_code} को वापस कतार में रख दिया गया है।",
        },
    },
    "CANCELLED_BY_SYSTEM": {
        "en": {
            "title": "Token Cancelled",
            "body": "Token {display_code} was cancelled due to multiple missed calls.",
        },
        "gu": {
            "title": "ટોકન રદ થયો",
            "body": "વારંવાર ચૂકી જવાના કારણે ટોકન {display_code} રદ કરવામાં આવ્યો છે.",
        },
        "hi": {
            "title": "टोकन रद्द हुआ",
            "body": "बार-बार कॉल छूटने के कारण टोकन {display_code} रद्द कर दिया गया है।",
        },
    },
    "EXPIRED": {
        "en": {
            "title": "Token Expired",
            "body": "Office is now closed. Token {display_code} has expired. Please visit tomorrow.",
        },
        "gu": {
            "title": "મુદત પૂરી થઈ",
            "body": "કચેરી હવે બંધ છે. ટોકન {display_code} ની મુદત પૂરી થઈ છે. કૃપા કરીને કાલે આવો.",
        },
        "hi": {
            "title": "टोकन समाप्त हुआ",
            "body": "कार्यालय अब बंद हो गया है। टोकन {display_code} समाप्त हो गया है। कृपया कल आएं।",
        },
    },
}


def render_notification(
    kind: str,
    language: str = "en",
    **kwargs: Any,
) -> dict[str, str]:
    lang = language if language in ["en", "gu", "hi"] else "en"
    kind_templates = TEMPLATES.get(kind, TEMPLATES["TOKEN_CONFIRMED"])
    template = kind_templates.get(lang, kind_templates["en"])

    title = template["title"]
    body = template["body"].format(**kwargs)

    return {"title": title, "body": body}
