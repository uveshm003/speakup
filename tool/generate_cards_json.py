#!/usr/bin/env python3
"""Generates assets/data/cards.json with 70 built-in topic cards."""
import json
import uuid

DIFFICULTIES = ["beginner", "intermediate", "advanced"]

CATEGORIES = [
    (
        "Opinion & Debate",
        [
            "Should social media have age limits?",
            "Is remote work better than office work?",
            "Should voting be mandatory in democracies?",
            "Are public figures entitled to privacy?",
            "Should university education be free for everyone?",
            "Is censorship ever justified online?",
            "Should countries prioritize climate over economic growth?",
            "Are standardized tests a fair measure of ability?",
            "Should junk food be taxed like tobacco?",
            "Is a four-day work week realistic for all industries?",
        ],
    ),
    (
        "Current Affairs",
        [
            "The rise of AI in everyday life",
            "Climate change and individual responsibility",
            "Global migration and border policies",
            "The future of cashless societies",
            "Energy transition and developing economies",
            "Misinformation and trust in news media",
            "Urban housing crises in major cities",
            "Public health systems after global pandemics",
            "Space exploration versus Earth-bound priorities",
            "Youth unemployment and the skills gap",
        ],
    ),
    (
        "Personal Growth",
        [
            "Overcoming the fear of failure",
            "Building consistent habits",
            "Setting boundaries without guilt",
            "Learning from criticism constructively",
            "Balancing ambition with mental health",
            "Finding purpose after a major setback",
            "The role of mentors in career growth",
            "Managing perfectionism in high performers",
            "Staying motivated without external rewards",
            "Journaling and self-reflection benefits",
        ],
    ),
    (
        "Technology",
        [
            "The impact of smartphones on human connection",
            "Should coding be taught in primary school?",
            "Privacy trade-offs in smart cities",
            "The ethics of facial recognition in public spaces",
            "Can technology solve loneliness?",
            "Open source versus proprietary software culture",
            "The environmental cost of data centers",
            "Wearables and the future of preventive healthcare",
            "Autonomous vehicles and road safety",
            "Digital minimalism in a hyper-connected world",
        ],
    ),
    (
        "Culture & Society",
        [
            "How social media shapes beauty standards",
            "The value of learning a second language",
            "Tradition versus progress in modern families",
            "Celebrity culture and young audiences",
            "Festivals as a window into national identity",
            "Volunteering and civic responsibility",
            "The decline of print newspapers",
            "Multiculturalism in the classroom",
            "Sports as a unifying force",
            "Public art and community pride",
        ],
    ),
    (
        "Business & Work",
        [
            "What makes a great leader?",
            "The gig economy and job security",
            "Diversity initiatives that actually work",
            "Remote onboarding and team culture",
            "Ethical dilemmas in sales targets",
            "Side hustles and work-life balance",
            "Corporate sustainability beyond marketing",
            "Negotiating salary with confidence",
            "Start-up culture versus corporate structure",
            "Customer feedback as a growth engine",
        ],
    ),
    (
        "Storytelling & Personal",
        [
            "Describe a moment that changed your perspective",
            "Talk about a person who influenced you most",
            "A challenge you overcame and what you learned",
            "A place that feels like home",
            "A skill you taught yourself and why it matters",
            "A book or film that shifted your worldview",
            "A time you had to apologize sincerely",
            "A goal you are working toward right now",
            "A tradition your family keeps alive",
            "A risk you are glad you took",
        ],
    ),
]


def guide_for(title: str, category: str) -> list[str]:
    return [
        f"Context: Frame why “{title}” matters today in {category.lower()}.",
        f"Angles: Compare at least two viewpoints people commonly hold.",
        f"Examples: Reference a real trend, study, or anecdote (hypothetical is fine).",
        f"Wrap-up: End with a balanced takeaway or a thoughtful question.",
    ]


def vocab_pack(n: int) -> list[dict[str, str]]:
    packs = [
        [
            ("nuance", "a subtle difference in meaning or opinion"),
            ("articulate", "to express thoughts clearly and effectively"),
            ("perspective", "a particular attitude toward something"),
            ("coherent", "logical and consistent"),
            ("stance", "an openly expressed opinion"),
        ],
        [
            ("implication", "a possible future effect or result"),
            ("scrutiny", "critical observation or examination"),
            ("precedent", "an earlier event that guides later decisions"),
            ("contentious", "likely to cause disagreement"),
            ("mitigate", "to make something less severe"),
        ],
        [
            ("resilience", "ability to recover from difficulties"),
            ("deliberate", "done consciously and intentionally"),
            ("accountability", "responsibility for actions"),
            ("catalyst", "something that causes change"),
            ("sustainable", "able to continue over time"),
        ],
        [
            ("infrastructure", "basic systems that support a society"),
            ("innovation", "a new idea, method, or product"),
            ("scalability", "ability to grow without losing performance"),
            ("latency", "delay before a response begins"),
            ("encryption", "encoding data so only authorized parties read it"),
        ],
        [
            ("solidarity", "unity among people with a common interest"),
            ("assimilation", "adopting the customs of a larger culture"),
            ("heritage", "traditions passed through generations"),
            ("polarization", "division into sharply contrasting groups"),
            ("empathy", "understanding others’ feelings"),
        ],
        [
            ("stakeholder", "anyone affected by a decision"),
            ("alignment", "agreement on goals or direction"),
            ("leverage", "using resources strategically for advantage"),
            ("benchmark", "a standard for measuring performance"),
            ("turnover", "rate at which employees leave a company"),
        ],
        [
            ("vulnerable", "open to emotional risk or harm"),
            ("gratitude", "thankfulness and appreciation"),
            ("milestone", "a significant stage in development"),
            ("authenticity", "being genuine and true to oneself"),
            ("reflection", "serious thought about experience"),
        ],
    ]
    return [{"word": w, "meaning": m} for w, m in packs[n % len(packs)]]


def main() -> None:
    out: list[dict] = []
    idx = 0
    for cat_name, titles in CATEGORIES:
        for title in titles:
            diff = DIFFICULTIES[idx % 3]
            out.append(
                {
                    "id": str(uuid.uuid4()),
                    "title": title,
                    "category": cat_name,
                    "difficulty": diff,
                    "guide": guide_for(title, cat_name),
                    "vocabBoost": vocab_pack(idx),
                    "isCustom": False,
                }
            )
            idx += 1
    assert len(out) == 70
    with open("assets/data/cards.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("Wrote 70 cards to assets/data/cards.json")


if __name__ == "__main__":
    main()
