# AI Reference Documents

Private reference documents for the Bay Navigator AI search system. These files reduce AI/LLM API costs by enabling pattern-based keyword matching without LLM calls.

**Purpose**: Map natural language queries to search keywords for Azure AI Search. This is NOT a chatbot - it enhances search by extracting relevant program keywords.

## Files

### common-queries.json

Maps common user query patterns directly to search keywords. Structure:

```json
{
  "query_patterns": {
    "category_name": {
      "pattern_name": {
        "patterns": ["trigger phrase 1", "trigger phrase 2"],
        "keywords_to_search": "search keywords for Azure AI Search"
      }
    }
  }
}
```

### program-categories.json

Maps program categories (food, housing, etc.) to search keywords. Structure:

```json
{
  "categories": {
    "category_id": {
      "name": "Display Name",
      "trigger_keywords": ["words that indicate this category"],
      "search_keywords": "keywords to add to search query"
    }
  }
}
```

### eligibility-groups.json

Maps demographic groups (seniors, veterans, etc.) to search keywords. Structure:

```json
{
  "groups": {
    "group_id": {
      "name": "Display Name",
      "trigger_keywords": ["words that indicate this group"],
      "search_keywords": "keywords to add to search query"
    }
  }
}
```

### bay-area-geography.json

Bay Area location data for geographic filtering. Used to detect user location from queries containing city names, counties, or ZIP codes.

## How It Works

1. User submits search query
2. System checks `common-queries.json` for pattern matches → returns `keywords_to_search`
3. If no match, detects categories/groups from query → adds their `search_keywords`
4. For short queries (≤3 words), uses synonym expansion only
5. LLM called only for complex queries that don't match any patterns

## Cost Savings

- Short queries: Skip LLM entirely
- Common patterns: Direct keyword mapping
- Category/group detection: Pre-built search term expansion
- LLM only needed for: Complex multi-word queries without pattern matches

## Maintenance

- Add new patterns to `common-queries.json` based on search analytics
- Update `trigger_keywords` when users use unexpected terminology
- Review `search_keywords` to ensure they match program listings in the database
