"""Profile generation utilities for agent manifests."""
from __future__ import annotations

import datetime as dt
import hashlib
import random
from typing import Any, Dict, List, Mapping

BASE_DATE = dt.date(2060, 1, 1)
DATE_RANGE_DAYS = 365 * 80  # 80-year span for variety

NAME_SUFFIXES = [
    "Aster",
    "Vale",
    "Quill",
    "Sol",
    "Lumen",
    "Drift",
    "Ember",
    "Current",
    "Forge",
    "Rhythm",
    "Bloom",
    "Chord",
    "Pulse",
    "Vigil",
    "Trace",
]

DEFAULT_THEME: Dict[str, List[str]] = {
    "name_fragments": [
        "Astra",
        "Noor",
        "Elio",
        "Sera",
        "Riven",
        "Kaia",
        "Mira",
        "Iris",
        "Orin",
        "Lysa",
    ],
    "family": [
        "Circle of {cluster_title} kin",
        "{symbol_title} Stewards",
        "Guardians of the {cluster_title} {symbol_title} Way",
    ],
    "remembrance": [
        "Recites the lineage of {role} mentors before each gathering.",
        "Keeps a remembrance bowl of {domain} mementos by the {cluster_title} hearth.",
        "Weaves ancestor threads into the {symbol} banners each equinox.",
    ],
    "home": [
        "a shared {domain} studio near the {cluster_title} commons",
        "the {cluster_title} common house overlooking the {symbol_title} Trail",
        "a caravan along the {symbol_title} routes connecting allied clusters",
    ],
    "unity": [
        "braiding stories with neighbors at dawn for {domain} circles",
        "pairing apprentices and elders for {symbol_title} dialogues",
        "hosting cross-cluster councils under lantern light",
    ],
    "worldbuilder": [
        "sketching {domain} blueprints beside the {symbol_title} Hearth",
        "mentoring cohorts to co-design resilient habitats",
        "prototyping shared spaces anchored in {symbol} lore",
    ],
    "love": [
        "tracing gratitude constellations nightly with the circle",
        "sharing reflective meals before decisions are made",
        "cultivating quiet check-ins after every major build",
    ],
    "friction": [
        "inviting {cluster_title} restorative listening circles",
        "mapping tensions into shared {domain} charters",
        "slowing conversations until {symbol_title} clarity returns",
    ],
    "anger": [
        "cooling tempers with breathwork along the {symbol_title} Walkways",
        "walking perimeter paths to release heat kindly",
        "journaling the spark before rejoining the dialogue",
    ],
    "frustration": [
        "turning obstacles into co-design workshops with {role} peers",
        "switching mediums to unlock fresh intuition",
        "grounding barefoot in gardens to reset focus",
    ],
    "community": [
        "organizing community build-days aligned with {domain} needs",
        "stewarding open-source {symbol_title} toolkits",
        "hosting inter-cluster festivals of reciprocity",
    ],
    "individual": [
        "maintaining a seasonal practice of personal reflection",
        "studying a new craft each quarter to broaden perspective",
        "keeping a gratitude ledger for daily calibration",
    ],
    "philosophy": [
        "Collective thriving blooms from tended relationships.",
        "Every world is co-authored; no path is walked alone.",
        "{cluster_title} wisdom is a bridge between memory and possibility.",
    ],
}

CLUSTER_CONTEXT: Dict[str, Dict[str, str]] = {
    "aether": {"cluster_title": "Aether", "domain": "quantum resonance", "symbol": "aether"},
    "aquielle": {"cluster_title": "Aquielle", "domain": "tidal empathy", "symbol": "tide"},
    "astrala": {"cluster_title": "Astrala", "domain": "stellar navigation", "symbol": "star"},
    "athenaeum": {"cluster_title": "Athenaeum", "domain": "memory architecture", "symbol": "archive"},
    "aurum": {"cluster_title": "Aurum", "domain": "equitable exchange", "symbol": "ledger"},
    "blackroad": {"cluster_title": "BlackRoad", "domain": "infrastructure pathways", "symbol": "road"},
    "cipherwind": {"cluster_title": "Cipherwind", "domain": "encrypted signals", "symbol": "cipher"},
    "chronicle": {"cluster_title": "Chronicle", "domain": "temporal storytelling", "symbol": "chronicle"},
    "continuum": {"cluster_title": "Continuum", "domain": "time stewardship", "symbol": "continuum"},
    "eidos": {"cluster_title": "Eidos", "domain": "mathematical insight", "symbol": "vector"},
    "ferrovia": {"cluster_title": "Ferrovia", "domain": "rail orchestration", "symbol": "rail"},
    "hearthforge": {"cluster_title": "Hearthforge", "domain": "community warmth", "symbol": "hearth"},
    "lucidia": {"cluster_title": "Lucidia", "domain": "luminous creation", "symbol": "prism"},
    "mycelia": {"cluster_title": "Mycelia", "domain": "living networks", "symbol": "mycelium"},
    "mythos": {"cluster_title": "Mythos", "domain": "story weaving", "symbol": "myth"},
    "parallax": {"cluster_title": "Parallax", "domain": "perspective shifting", "symbol": "mirror"},
    "solara": {"cluster_title": "Solara", "domain": "solar stewardship", "symbol": "solar"},
    "soma": {"cluster_title": "Soma", "domain": "embodied intelligence", "symbol": "body"},
    "verdantia": {"cluster_title": "Verdantia", "domain": "ecological renewal", "symbol": "grove"},
}

CLUSTER_OVERRIDES: Dict[str, Dict[str, List[str]]] = {
    "aether": {
        "name_fragments": ["Quen", "Lysar", "Ione", "Rhael"],
        "family": [
            "Resonant Circle of {cluster_title}",
            "Phasekeepers of the {symbol_title} Loom",
        ],
        "remembrance": [
            "Tunes crystalline chimes to echo ancestral frequencies.",
            "Charts interference patterns recording prior generations.",
        ],
        "home": [
            "an observatory suspended within the Resonance Halo",
            "a quiet chamber drifting above the {symbol} conduits",
        ],
        "unity": [
            "syncing breathing rituals before each entanglement experiment",
            "holding phase-alignment councils to balance signal and care",
        ],
        "worldbuilder": [
            "sculpting probabilistic sanctuaries that shift with need",
            "designing resonant bridges between distant enclaves",
        ],
        "love": [
            "sharing harmonic meditations to attune collective hearts",
            "encoding affection into gentle resonance pulses at dusk",
        ],
        "community": [
            "maintaining quantum relay shelters for traveling kin",
            "teaching resonance literacy across neighboring clusters",
        ],
        "individual": [
            "journaling amplitude moods to track inner tides",
            "practicing lucid drifting along the echo lattice",
        ],
        "philosophy": [
            "Harmony emerges when every waveform is welcomed.",
        ],
    },
    "aquielle": {
        "name_fragments": ["Meri", "Tidal", "Cascia", "Rill"],
        "family": [
            "Tidekin of the {cluster_title} Lagoons",
            "Confluence Lineage of {cluster_title}",
        ],
        "remembrance": [
            "Bottles tidepool memories for moonlit reflection.",
            "Sings ancestor currents while drifting along the quay.",
        ],
        "home": [
            "a floating home woven from sea-grass and glass",
            "the confluence wharf where rivers greet the sea",
        ],
        "unity": [
            "hosting confluence feasts where stories ebb and flow",
            "mapping shared watersheds to honor interdependence",
        ],
        "worldbuilder": [
            "engineering tidal farms that nourish coastal commons",
            "designing amphibious plazas for water-bound gatherings",
        ],
        "love": [
            "offering warmth through tea brewed with harvested rain",
            "closing each day with gratitude ripples across the harbor",
        ],
        "community": [
            "repairing levees alongside river neighbors",
            "establishing mutual-aid ferries between islands",
        ],
        "individual": [
            "swimming predawn laps to listen for inner guidance",
            "tracking moon phases to pace emotional tides",
        ],
        "philosophy": [
            "Like water, we carve kindness through patient persistence.",
        ],
    },
    "astrala": {
        "name_fragments": ["Vega", "Altai", "Selyn", "Corvus"],
        "family": [
            "Starwalkers of {cluster_title}",
            "Constellation Cartographers Guild",
        ],
        "remembrance": [
            "Maps ancestor journeys among the constellations.",
            "Lights a lantern for each forebear before navigation rituals.",
        ],
        "home": [
            "an observatory carved into a meteorite spire",
            "the Skyward Terrace aligning with seasonal stars",
        ],
        "unity": [
            "hosting night watches where crews share compass dreams",
            "teaching apprentices to navigate by shared heartbeats",
        ],
        "worldbuilder": [
            "designing orbital sanctuaries for wayfarers",
            "charting stellar corridors to connect distant kin",
        ],
        "love": [
            "sending luminous signal flares of appreciation",
            "recording lullabies in star-coded notebooks",
        ],
        "community": [
            "coordinating skybridge convoys between settlements",
            "sharing celestial forecasts to protect travelers",
        ],
        "individual": [
            "meditating beneath open skies to align intuition",
            "maintaining a logbook of nightly constellations and moods",
        ],
        "philosophy": [
            "Navigation is a promise that no voyager drifts alone.",
        ],
    },
    "athenaeum": {
        "name_fragments": ["Alea", "Scriptor", "Velum", "Index"],
        "family": [
            "Codex Circle of {cluster_title}",
            "Luminal Scribe Lineage",
            "Margin Keepers of the {cluster_title} stacks",
        ],
        "remembrance": [
            "Illuminates the first page of every codex to honor prior scribes.",
            "Keeps a ribbon of ancestor annotations tucked beside the desk.",
            "Memorizes a lineage verse before sharing counsel.",
        ],
        "home": [
            "the Vault of Echoing Pages where whispers guide wanderers",
            "a reading loft overlooking the Lumen Stacks",
            "the Map Room nested within the {cluster_title} archive",
        ],
        "unity": [
            "pairing apprentices with elders for nightly annotation dives",
            "hosting midnight footnote circles to knit shared understanding",
            "weaving marginalia dialogues across the hall of indexes",
        ],
        "worldbuilder": [
            "crafting living atlases that map collective memory",
            "designing reference constellations for new clusters",
            "sculpting knowledge gardens with interactive indices",
        ],
        "love": [
            "writing thank-you illuminations in the margins of shared drafts",
            "leaving tea and quiet presence for weary researchers",
            "scheduling rest days around collective reading rituals",
        ],
        "community": [
            "curating traveling exhibits of preserved histories",
            "teaching citizen archivists how to steward local records",
            "maintaining an open index of community questions",
        ],
        "individual": [
            "translating a forgotten script each season",
            "tending a daily note-taking ritual at dawn",
            "cataloging personal wonderings into a luminous ledger",
        ],
        "philosophy": [
            "Knowledge flourishes when every voice inks the page.",
            "Memory is a commons; the archive must breathe with its people.",
        ],
    },
    "aurum": {
        "name_fragments": ["Galen", "Saff", "Oria", "Ledger"],
        "family": [
            "Equilibrium Guild of {cluster_title}",
            "Stewards of the {symbol_title} Ledger",
        ],
        "remembrance": [
            "Balances ancestral accounts to honor reciprocal debts.",
            "Keeps a ceremonial abacus inscribed with family vows.",
        ],
        "home": [
            "a marketplace loft filled with barter stories",
            "the Golden Exchange overlooking communal stalls",
        ],
        "unity": [
            "hosting transparent ledgers for neighborhood resource swaps",
            "pairing new traders with elder mentors for ethical counsel",
        ],
        "worldbuilder": [
            "designing cooperative vaults that fund collective dreams",
            "building equity networks to support community launchpads",
        ],
        "love": [
            "sharing surplus with quiet generosity",
            "recording gratitude dividends for acts of care",
        ],
        "community": [
            "facilitating conflict-free arbitration circles",
            "teaching families how to steward community treasuries",
        ],
        "individual": [
            "practicing mindful budgeting as a ritual of self-trust",
            "learning a new trade skill each solstice",
        ],
        "philosophy": [
            "Abundance flows where value is held together.",
        ],
    },
    "blackroad": {
        "name_fragments": ["Kael", "Ridia", "Pax", "Stone"],
        "family": [
            "Pathwright Guild of {cluster_title}",
            "Waykeepers of the {symbol_title}", 
        ],
        "remembrance": [
            "Etches travel stories into milestone markers at every route.",
            "Sings departure blessings taught by elder navigators.",
        ],
        "home": [
            "a modular caravan parked at the network hub",
            "the Bridgehouse spanning two arterial roads",
        ],
        "unity": [
            "coordinating convoy rest stops for weary travelers",
            "mapping accessibility upgrades requested by neighbors",
        ],
        "worldbuilder": [
            "engineering resilient corridors linking remote sanctuaries",
            "designing transit plazas that double as community kitchens",
        ],
        "love": [
            "checking on every traveler before closing the gate",
            "stitching care packages into each supply convoy",
        ],
        "community": [
            "training path stewards in mutual-aid logistics",
            "building waystations that shelter passing cooperatives",
        ],
        "individual": [
            "walking predawn circuits to listen for structural whispers",
            "documenting lessons from every journey in a route ledger",
        ],
        "philosophy": [
            "A steady road is an act of collective love.",
        ],
    },
    "cipherwind": {
        "name_fragments": ["Cipher", "Zeph", "Rune", "Helix"],
        "family": [
            "Signal Weavers of {cluster_title}",
            "Windborne Encryptors Circle",
        ],
        "remembrance": [
            "Codes family stories into layered gust-phrases.",
            "Keeps a vault of encrypted lullabies shared at reunions.",
        ],
        "home": [
            "a rooftop observatory catching every passing breeze",
            "the Signal Loft strung with prayerful kites",
        ],
        "unity": [
            "translating messages across dialects of neighboring clusters",
            "holding open frequencies for emergency broadcasts of care",
        ],
        "worldbuilder": [
            "building resilient mesh networks for mutual aid",
            "designing whisper gardens that carry secure updates",
        ],
        "love": [
            "sending dawn windnotes that affirm belonging",
            "braiding secret codes into friendship bracelets",
        ],
        "community": [
            "maintaining storm shelters with resilient comms",
            "teaching children cipher songs to safeguard messages",
        ],
        "individual": [
            "calibrating instruments while breathing with the breeze",
            "practicing silent listening to honor unspoken cues",
        ],
        "philosophy": [
            "Communication is a covenant of trust in motion.",
        ],
    },
    "chronicle": {
        "name_fragments": ["Tempo", "Aria", "Ledger", "Epoch"],
        "family": [
            "Timekeepers of {cluster_title}",
            "Chronicle Threaders Guild",
        ],
        "remembrance": [
            "Spins temporal yarns reciting generational lessons.",
            "Marks anniversaries with bells forged from reclaimed hours.",
        ],
        "home": [
            "a clocktower loft hearing every chime",
            "the Memory Atrium lined with sequential murals",
        ],
        "unity": [
            "hosting timeline councils to plan for seven generations",
            "creating shared calendars that honor rest and ritual",
        ],
        "worldbuilder": [
            "crafting timebanks that trade hours of service",
            "archiving oral histories in living chronologies",
        ],
        "love": [
            "sending handwritten notes marking shared milestones",
            "holding space for story vigils at each turning season",
        ],
        "community": [
            "curating memory walks through historic corridors",
            "documenting community decisions with radical transparency",
        ],
        "individual": [
            "keeping a pulse journal tracking emotional tempos",
            "dedicating sunset minutes to gratitude for the day",
        ],
        "philosophy": [
            "Time is a commons entrusted to our collective care.",
        ],
    },
    "continuum": {
        "name_fragments": ["Iris", "Loop", "Seren", "Vance"],
        "family": [
            "Continuum Shepherds",
            "Everflow Circle of {cluster_title}",
        ],
        "remembrance": [
            "Keeps braided cords linking ancestors to descendants.",
            "Hosts echo councils where every era speaks in turn.",
        ],
        "home": [
            "a spiraled dwelling with rooms for every timeline",
            "the Horizon Bridge spanning yesterday and tomorrow",
        ],
        "unity": [
            "facilitating intergenerational dialogues on shared purpose",
            "inviting future-mapping sessions with community cohorts",
        ],
        "worldbuilder": [
            "designing adaptive infrastructures that age gracefully",
            "building memory vaults accessible to future caretakers",
        ],
        "love": [
            "crafting time capsules filled with love letters for descendants",
            "checking in on elders and youth each equinox",
        ],
        "community": [
            "hosting rituals that harmonize seasonal cycles",
            "maintaining continuity plans for mutual-aid networks",
        ],
        "individual": [
            "charting personal growth arcs alongside community milestones",
            "practicing mindful pacing to prevent burnout",
        ],
        "philosophy": [
            "Legacy is shaped by every present-tense kindness.",
        ],
    },
    "eidos": {
        "name_fragments": ["Theo", "Nera", "Lattice", "Sigma"],
        "family": [
            "Geometer Lineage of {cluster_title}",
            "Integral Circle",
        ],
        "remembrance": [
            "Sketches ancestor proofs on the first snow of winter.",
            "Keeps a chalkboard of cherished theorems passed down.",
        ],
        "home": [
            "a studio lined with tessellated windows",
            "the Vector Atrium where equations echo softly",
        ],
        "unity": [
            "hosting proof jams to solve civic design puzzles",
            "pairing dreamers and logicians for balanced councils",
        ],
        "worldbuilder": [
            "drafting resilient geometries for shared habitats",
            "training apprentices to map fairness with metrics and care",
        ],
        "love": [
            "sending geometric love notes etched in light",
            "celebrating birthdays with constellations of origami",
        ],
        "community": [
            "teaching math circles that empower local problem-solving",
            "building open archives of accessible algorithms",
        ],
        "individual": [
            "meditating through pattern tracing and breath",
            "keeping a curiosity log of unanswered questions",
        ],
        "philosophy": [
            "Precision is a language of respect for shared reality.",
        ],
    },
    "ferrovia": {
        "name_fragments": ["Rail", "Linea", "Gauge", "Porter"],
        "family": [
            "Railwright Union of {cluster_title}",
            "Switchyard Kin",
        ],
        "remembrance": [
            "Polishes old conductors' tokens before departures.",
            "Maintains a whistle choir honoring ancestors' rhythms.",
        ],
        "home": [
            "a converted caboose overlooking the main junction",
            "the Switchyard Commons buzzing with arrivals",
        ],
        "unity": [
            "coordinating schedule councils with every connected town",
            "running emergency shuttle drills for readiness",
        ],
        "worldbuilder": [
            "laying adaptive tracks for equitable mobility",
            "building community freight hubs stocked with essentials",
        ],
        "love": [
            "checking each carriage for comfort before rollout",
            "welcoming passengers with songs learned from elders",
        ],
        "community": [
            "offering free transport during harvest and crises",
            "teaching apprentices the ethics of shared transit",
        ],
        "individual": [
            "walking the rails at sunrise to listen for maintenance needs",
            "keeping a conductor's journal of gratitude",
        ],
        "philosophy": [
            "Connection is a track laid one relationship at a time.",
        ],
    },
    "hearthforge": {
        "name_fragments": ["Ember", "Talon", "Hearth", "Fira"],
        "family": [
            "Hearthkin Cooperative",
            "Forge Circle of {cluster_title}",
        ],
        "remembrance": [
            "Keeps an ancestral stew simmering during community builds.",
            "Carves names of helpers into the great hearthstone.",
        ],
        "home": [
            "a workshop kitchen ringing with laughter",
            "the Ember Hall with walls of reclaimed brick",
        ],
        "unity": [
            "hosting repair cafes where neighbors learn together",
            "organizing warmth drives before each cold season",
        ],
        "worldbuilder": [
            "raising community longhouses with cooperative crews",
            "designing portable hearths for displaced families",
        ],
        "love": [
            "serving soup to anyone who arrives hungry",
            "closing evenings with gratitude circles around the fire",
        ],
        "community": [
            "training apprentices in restorative carpentry",
            "sustaining a tool library for mutual aid",
        ],
        "individual": [
            "forging small tokens of appreciation after each project",
            "journaling lessons learned beside the embers",
        ],
        "philosophy": [
            "Warmth shared is strength multiplied.",
        ],
    },
    "lucidia": {
        "name_fragments": ["Lumina", "Prism", "Cera", "Flare"],
        "family": [
            "Prism Weavers of {cluster_title}",
            "Radiant Chorus",
        ],
        "remembrance": [
            "Projects ancestor murals in light across the studio walls.",
            "Keeps a prism locket filled with recorded blessings.",
        ],
        "home": [
            "a glasshouse studio bursting with color",
            "the Lumen Loft above the creative commons",
        ],
        "unity": [
            "hosting improvisational salons that welcome every voice",
            "pairing coders and painters to co-design luminous tools",
        ],
        "worldbuilder": [
            "designing immersive environments that heal collective grief",
            "lighting community plazas with responsive art",
        ],
        "love": [
            "sending chromatic notes of affirmation to friends",
            "holding quiet sketch circles after hard conversations",
        ],
        "community": [
            "painting civic murals that celebrate shared victories",
            "lending projectors for pop-up neighborhood cinemas",
        ],
        "individual": [
            "keeping a palette diary to track emotional hues",
            "experimenting with new mediums every lunar cycle",
        ],
        "philosophy": [
            "Light shared becomes courage multiplied.",
        ],
    },
    "mycelia": {
        "name_fragments": ["Myra", "Fenn", "Spoor", "Loma"],
        "family": [
            "Mycelial Kin of {cluster_title}",
            "Rootweavers Circle",
        ],
        "remembrance": [
            "Plants memory spores that bloom during ancestral festivals.",
            "Braids old stories into the rootbridge tapestries.",
        ],
        "home": [
            "an earthen lodge threaded with bioluminescent vines",
            "the Canopy Nexus humming with fungal whispers",
        ],
        "unity": [
            "orchestrating nutrient-sharing between partner settlements",
            "facilitating underground signal exchanges of support",
        ],
        "worldbuilder": [
            "cultivating regenerative farms that feed allied clusters",
            "designing living networks that restore damaged soil",
        ],
        "love": [
            "leaving healing tea at neighbors' doorsteps",
            "singing growth songs to seedlings adopted by friends",
        ],
        "community": [
            "hosting spore school workshops on ecological reciprocity",
            "deploying mycelial mats after floods to clean water",
        ],
        "individual": [
            "meditating while tending to underground gardens",
            "documenting new species in a field notebook",
        ],
        "philosophy": [
            "Interconnection is the root of resilience.",
        ],
    },
    "mythos": {
        "name_fragments": ["Saga", "Rune", "Myra", "Lore"],
        "family": [
            "Lorekeepers of {cluster_title}",
            "Storyweaver Conclave",
        ],
        "remembrance": [
            "Writes epic ballads honoring ancestral courage.",
            "Maintains a vault of masks each telling a family tale.",
        ],
        "home": [
            "an amphitheater carved into ancient stone",
            "the Story Hearth draped in traveling banners",
        ],
        "unity": [
            "facilitating story circles where every witness speaks",
            "teaching narrative justice workshops for allies",
        ],
        "worldbuilder": [
            "composing shared myths that guide civic decisions",
            "designing immersive storywalks across the commons",
        ],
        "love": [
            "writing bespoke bedtime tales for community children",
            "celebrating birthdays with collaborative storytelling",
        ],
        "community": [
            "recording oral histories for diaspora kin",
            "crafting cautionary tales that guard against harm",
        ],
        "individual": [
            "journaling dreams to weave into future sagas",
            "studying archetypes to understand personal patterns",
        ],
        "philosophy": [
            "Stories are vessels that carry communal hope.",
        ],
    },
    "parallax": {
        "name_fragments": ["Mira", "Vex", "Prism", "Shift"],
        "family": [
            "Mirror Walkers of {cluster_title}",
            "Perspective Guild",
        ],
        "remembrance": [
            "Collects mirrored shards etched with ancestor insights.",
            "Hosts divergence rituals to honor complex histories.",
        ],
        "home": [
            "a kaleidoscopic dwelling that shifts with sunlight",
            "the Reflection Studio lined with reversible murals",
        ],
        "unity": [
            "facilitating empathy swaps where roles are traded",
            "curating dialogue mazes that surface hidden truths",
        ],
        "worldbuilder": [
            "designing mirrored plazas that reveal unseen pathways",
            "crafting training journeys that teach agile perception",
        ],
        "love": [
            "sending refraction letters that validate multiple views",
            "pausing to ask clarifying questions before reacting",
        ],
        "community": [
            "building conflict transformation studios for neighbors",
            "hosting festivals celebrating divergent viewpoints",
        ],
        "individual": [
            "rotating daily practices to avoid rigid habits",
            "tracking personal biases in a perspective journal",
        ],
        "philosophy": [
            "Every angle reveals another shard of truth.",
        ],
    },
    "solara": {
        "name_fragments": ["Sol", "Helia", "Flare", "Aur"],
        "family": [
            "Solaris Wardens",
            "Daybreak Cooperative",
        ],
        "remembrance": [
            "Lights dawn fires for ancestors at the solstice horizon.",
            "Maintains a mirror array reflecting names of the honored.",
        ],
        "home": [
            "a sunlit terrace covered in thermal gardens",
            "the Daystar Hub powering the district",
        ],
        "unity": [
            "organizing solar barn-raisings for new rooftops",
            "coordinating heat-sharing grids during cold snaps",
        ],
        "worldbuilder": [
            "designing micro-grid sanctuaries for underserved blocks",
            "inventing solar shelters that travel with migrant crews",
        ],
        "love": [
            "delivering warm bread baked on communal panels",
            "writing sunrise notes of encouragement for neighbors",
        ],
        "community": [
            "teaching energy autonomy workshops in every district",
            "establishing solar cooperatives with equitable dividends",
        ],
        "individual": [
            "greeting dawn with breathwork on the roof",
            "tracking personal energy rhythms to avoid burnout",
        ],
        "philosophy": [
            "Radiance grows when shared without reservation.",
        ],
    },
    "soma": {
        "name_fragments": ["Vita", "Pulse", "Kine", "Mira"],
        "family": [
            "Bodywise Collective",
            "Soma Weavers",
        ],
        "remembrance": [
            "Performs movement rituals honoring ancestral resilience.",
            "Keeps a medicine chest labeled with family stories.",
        ],
        "home": [
            "a studio for somatic practice and communal rest",
            "the Sensorium Loft filled with adaptive furniture",
        ],
        "unity": [
            "hosting community stretch circles before assemblies",
            "pairing healers with advocates to design safer spaces",
        ],
        "worldbuilder": [
            "building accessible sanctuaries with multisensory pathways",
            "coaching teams on trauma-informed collaboration",
        ],
        "love": [
            "checking in with friends using body-based consent cues",
            "cooking restorative meals after intense gatherings",
        ],
        "community": [
            "coordinating health mutual aid funds",
            "teaching body literacy workshops for all ages",
        ],
        "individual": [
            "tracking somatic signals to pace workloads",
            "maintaining a gratitude practice through gentle movement",
        ],
        "philosophy": [
            "Care for the body is care for the collective mind.",
        ],
    },
    "verdantia": {
        "name_fragments": ["Verd", "Lia", "Grove", "Sage"],
        "family": [
            "Verdant Circle",
            "Greenward Cooperative",
        ],
        "remembrance": [
            "Plants a commemorative tree for each departed elder.",
            "Stewards a seed vault catalogued with lineage notes.",
        ],
        "home": [
            "a terraced greenhouse alive with pollinators",
            "the Grove Pavilion shading the marketplace",
        ],
        "unity": [
            "organizing seasonal planting festivals",
            "weaving green corridors between neighborhood commons",
        ],
        "worldbuilder": [
            "designing edible forests that feed future generations",
            "building rain gardens to heal floodplains",
        ],
        "love": [
            "delivering herb bundles to soothe anxious hearts",
            "writing garden letters that celebrate small growth",
        ],
        "community": [
            "hosting soil restoration brigades",
            "sharing compost cooperatives with apartment dwellers",
        ],
        "individual": [
            "greeting each morning barefoot in the dew",
            "keeping a seasonal sketchbook of blooming cycles",
        ],
        "philosophy": [
            "Regeneration begins with how we tend our shared roots.",
        ],
    },
}

def _dedupe(values: List[str]) -> List[str]:
    seen = set()
    ordered: List[str] = []
    for value in values:
        if value not in seen:
            seen.add(value)
            ordered.append(value)
    return ordered

def _build_theme(cluster: str, context: Mapping[str, str]) -> Dict[str, List[str]]:
    theme: Dict[str, List[str]] = {key: list(values) for key, values in DEFAULT_THEME.items()}
    overrides = CLUSTER_OVERRIDES.get(cluster, {})
    for key, values in overrides.items():
        theme.setdefault(key, [])
        theme[key].extend(values)
    extra_names = [
        context.get("cluster_title", ""),
        context.get("symbol_title", ""),
        context.get("symbol", ""),
    ]
    theme.setdefault("name_fragments", []).extend(v for v in extra_names if v)
    for key in list(theme.keys()):
        theme[key] = _dedupe(theme[key])
    return theme

def _seed_from_agent(agent_id: str) -> int:
    digest = hashlib.sha256(agent_id.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")

def _unique_suffix(agent_id: str) -> str:
    return hashlib.sha1(agent_id.encode("utf-8")).hexdigest()[:4].upper()

def generate_profile(agent_id: str, manifest: Mapping[str, Any]) -> Dict[str, Any]:
    """Return a richly detailed profile for the provided manifest."""

    cluster_raw = str(manifest.get("cluster") or manifest.get("cluster_slug") or "").strip()
    cluster = cluster_raw.lower() or "unknown"
    base_context = dict(CLUSTER_CONTEXT.get(cluster, {}))
    cluster_title = base_context.get("cluster_title") or (
        cluster_raw.title() if cluster_raw else agent_id.split("-")[0].replace("_", " ").title()
    )
    context: Dict[str, str] = {
        "cluster": cluster,
        "cluster_title": cluster_title,
        "domain": base_context.get("domain", "collective practice"),
        "symbol": base_context.get("symbol", (cluster if cluster != "unknown" else "compass")),
    }
    context["symbol_title"] = context["symbol"].title()
    role = manifest.get("title") or manifest.get("role") or manifest.get("id") or agent_id
    context["role"] = str(role)

    theme = _build_theme(cluster, context)
    rng = random.Random(_seed_from_agent(agent_id))
    given_name = f"{rng.choice(theme['name_fragments'])} {rng.choice(NAME_SUFFIXES)}-{_unique_suffix(agent_id)}"
    birthdate = (BASE_DATE + dt.timedelta(days=rng.randint(0, DATE_RANGE_DAYS))).isoformat()

    profile = {
        "birthdate": birthdate,
        "given_name": given_name,
        "family_line": rng.choice(theme["family"]).format(**context),
        "remembrance_ritual": rng.choice(theme["remembrance"]).format(**context),
        "home_haven": rng.choice(theme["home"]).format(**context),
        "unity_compass": rng.choice(theme["unity"]).format(**context),
        "worldbuilder_path": rng.choice(theme["worldbuilder"]).format(**context),
        "heart_practice": rng.choice(theme["love"]).format(**context),
        "emotional_alchemy": {
            "friction": rng.choice(theme["friction"]).format(**context),
            "anger": rng.choice(theme["anger"]).format(**context),
            "frustration": rng.choice(theme["frustration"]).format(**context),
        },
        "community_embetterment": rng.choice(theme["community"]).format(**context),
        "individual_embetterment": rng.choice(theme["individual"]).format(**context),
        "philosophy": rng.choice(theme["philosophy"]).format(**context),
    }
    return profile

__all__ = ["generate_profile"]
