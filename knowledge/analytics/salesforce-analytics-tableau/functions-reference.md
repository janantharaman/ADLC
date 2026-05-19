---
source: help.tableau.com — Functions All Categories; Table Calculations; Parameters; Reference Lines (2026-05-17)
product: Tableau
section: functions-reference
last-updated: 2026-05-17
---

# Tableau — Functions Reference

## Number Functions

| Function | Syntax | Description |
|---|---|---|
| ABS | `ABS(number)` | Absolute value |
| CEILING | `CEILING(number)` | Rounds up to nearest integer |
| FLOOR | `FLOOR(number)` | Rounds down to nearest integer |
| ROUND | `ROUND(number, [decimals])` | Rounds to specified decimal places |
| SIGN | `SIGN(number)` | Returns -1, 0, or 1 |
| SQRT | `SQRT(number)` | Square root |
| SQUARE | `SQUARE(number)` | Square of a number |
| POWER | `POWER(number, power)` | Raises number to power |
| EXP | `EXP(number)` | e raised to given power |
| LN | `LN(number)` | Natural logarithm |
| LOG | `LOG(number, [base])` | Logarithm — default base 10 |
| DIV | `DIV(int1, int2)` | Integer division result |
| MAX | `MAX(expr1, expr2)` | Larger of two values |
| MIN | `MIN(expr1, expr2)` | Smaller of two values |
| ZN | `ZN(expression)` | Returns expression or 0 if null |
| PI | `PI()` | Returns 3.14159... |
| HEXBINX / HEXBINY | `HEXBINX(x, y)` | Maps x/y coordinates to hexagonal bin |

## String Functions

| Function | Syntax | Description |
|---|---|---|
| CONTAINS | `CONTAINS(string, substring)` | True if string contains substring |
| STARTSWITH | `STARTSWITH(string, substring)` | True if string starts with substring |
| ENDSWITH | `ENDSWITH(string, substring)` | True if string ends with substring |
| FIND | `FIND(string, substring, [start])` | Index position of substring |
| FINDNTH | `FINDNTH(string, substring, n)` | Position of nth occurrence |
| LEFT | `LEFT(string, n)` | Leftmost n characters |
| RIGHT | `RIGHT(string, n)` | Rightmost n characters |
| MID | `MID(string, start, [length])` | Substring from start position |
| LEN | `LEN(string)` | Length of string |
| UPPER | `UPPER(string)` | All uppercase |
| LOWER | `LOWER(string)` | All lowercase |
| PROPER | `PROPER(string)` | Title case |
| TRIM | `TRIM(string)` | Remove leading and trailing spaces |
| LTRIM | `LTRIM(string)` | Remove leading spaces |
| RTRIM | `RTRIM(string)` | Remove trailing spaces |
| REPLACE | `REPLACE(string, old, new)` | Replace substring |
| SPLIT | `SPLIT(string, delimiter, token)` | Extract token by delimiter and position |
| SPACE | `SPACE(n)` | Returns n repeated spaces |
| ASCII | `ASCII(string)` | ASCII code of first character |
| CHAR | `CHAR(number)` | Character from ASCII code |

## Date Functions

| Function | Syntax | Description |
|---|---|---|
| TODAY | `TODAY()` | Current date |
| NOW | `NOW()` | Current date and time |
| YEAR | `YEAR(date)` | Year as integer |
| QUARTER | `QUARTER(date)` | Quarter as integer (1–4) |
| MONTH | `MONTH(date)` | Month as integer (1–12) |
| WEEK | `WEEK(date)` | Week as integer |
| DAY | `DAY(date)` | Day as integer (1–31) |
| DATEPART | `DATEPART('date_part', date)` | Date part as integer |
| DATENAME | `DATENAME('date_part', date)` | Date part as string |
| DATETRUNC | `DATETRUNC('date_part', date)` | Truncates date to specified level |
| DATEADD | `DATEADD('date_part', interval, date)` | Adds interval to date |
| DATEDIFF | `DATEDIFF('date_part', date1, date2)` | Difference between two dates |
| DATE | `DATE(expression)` | Converts to date |
| DATEPARSE | `DATEPARSE('format', string)` | Parses string to date using format |
| MAKEDATETIME | `MAKEDATETIME(date, time)` | Combines date and time |
| MAKEDATE | `MAKEDATE(year, month, day)` | Constructs date from parts |
| ISDATE | `ISDATE(string)` | True if string is valid date |

**date_part values:** `'year'`, `'quarter'`, `'month'`, `'week'`, `'day'`, `'hour'`, `'minute'`, `'second'`, `'iso_year'`, `'iso_quarter'`, `'iso_week'`, `'iso_weekday'`

## Logical Functions

| Function | Syntax | Description |
|---|---|---|
| IF | `IF test THEN value [ELSEIF test THEN value ...] [ELSE default] END` | Returns value for first true test |
| IIF | `IIF(test, then, else, [unknown])` | Inline conditional — returns one of two values |
| CASE | `CASE expr WHEN val THEN result ... [ELSE default] END` | Matches expression to values |
| IFNULL | `IFNULL(expr1, expr2)` | Returns expr1 if not null, else expr2 |
| ISNULL | `ISNULL(expression)` | True if expression is null |
| ZN | `ZN(expression)` | Returns expression or 0 if null |
| AND / OR / NOT | Logical operators | Boolean operations |
| IN | `expr IN (val1, val2, ...)` | True if expr matches any listed value |

## Aggregate Functions

| Function | Description |
|---|---|
| `SUM(expression)` | Sum of all values; nulls ignored |
| `AVG(expression)` | Average; nulls ignored |
| `COUNT(expression)` | Count of non-null items |
| `COUNTD(expression)` | Count of distinct non-null items |
| `MAX(expression)` | Maximum aggregated value |
| `MIN(expression)` | Minimum aggregated value |
| `MEDIAN(expression)` | Median; nulls ignored |
| `PERCENTILE(expr, number)` | Value at specified percentile (0.0–1.0) |
| `STDEV(expression)` | Sample standard deviation |
| `STDEVP(expression)` | Population standard deviation |
| `VAR(expression)` | Sample variance |
| `VARP(expression)` | Population variance |
| `CORR(expr1, expr2)` | Pearson correlation coefficient (-1 to 1) |
| `COVAR(expr1, expr2)` | Sample covariance |
| `COVARP(expr1, expr2)` | Population covariance |
| `ATTR(expression)` | Returns value if all rows have same value; asterisk (*) if multiple |
| `COLLECT(spatial)` | Combines spatial field values |

## User Functions

| Function | Description |
|---|---|
| `USERNAME()` | Current user's username |
| `FULLNAME()` | Current user's full name |
| `USERDOMAIN()` | Current user's domain |
| `ISMEMBEROF('group')` | True if current user belongs to the named group |
| `ISUSERNAME('name')` | True if current username matches |
| `ISFULLNAME('name')` | True if current full name matches |
| `USERATTRIBUTE('attr')` | Returns value from JWT / SAML attribute |
| `USERATTRIBUTEINCLUDES('attr', 'value')` | True if user's attribute matches expected value |

**User function use cases:** Row-level security (filter views to current user's data), personalised greetings, dynamic parameter defaults.

## Table Calculation Functions

Table calculations compute on the visible result set in the view, not on raw data. They are applied last in the order of operations.

### Positional

| Function | Description |
|---|---|
| `INDEX()` | Current row number in the partition (1-based) |
| `FIRST()` | Rows from current to first row (0 at first, -N at last) |
| `LAST()` | Rows from current to last row (0 at last, N at first) |
| `SIZE()` | Number of rows in the partition |

### Lookup

| Function | Description |
|---|---|
| `LOOKUP(expr, [offset])` | Value of expr at a row offset from current (-1 = prior row, 1 = next) |
| `PREVIOUS_VALUE(expr)` | Value from the previous row in partition |

### Running

| Function | Description |
|---|---|
| `RUNNING_SUM(expr)` | Cumulative sum from first row to current |
| `RUNNING_AVG(expr)` | Cumulative average from first row |
| `RUNNING_MIN(expr)` | Cumulative minimum |
| `RUNNING_MAX(expr)` | Cumulative maximum |
| `RUNNING_COUNT(expr)` | Cumulative count |

### Window

`WINDOW_` functions compute over a sliding window: `[start, end]` where 0 = current row, negative = before, positive = after, FIRST()/LAST() = start/end of partition.

| Function | Description |
|---|---|
| `WINDOW_SUM(expr, [s, e])` | Sum within window |
| `WINDOW_AVG(expr, [s, e])` | Average within window |
| `WINDOW_MIN / WINDOW_MAX` | Min/max within window |
| `WINDOW_COUNT(expr, [s, e])` | Count within window |
| `WINDOW_MEDIAN(expr, [s, e])` | Median within window |
| `WINDOW_STDEV / WINDOW_VAR` | Std dev / variance within window |
| `WINDOW_PERCENTILE(expr, n, [s, e])` | Percentile within window |
| `WINDOW_CORR / WINDOW_COVAR` | Correlation / covariance within window |

**Moving average (3-period):** `WINDOW_AVG(SUM([Sales]), -2, 0)`

### Rank

| Function | Description |
|---|---|
| `RANK(expr, ['asc'|'desc'])` | Standard competition rank (ties share rank, next skips) |
| `RANK_DENSE(expr)` | Dense rank — no gaps after ties |
| `RANK_MODIFIED(expr)` | Modified competition rank (ties get the last rank in the tie) |
| `RANK_UNIQUE(expr)` | Unique sequential rank — no ties |
| `RANK_PERCENTILE(expr)` | Percentile rank |

### Totals

| Function | Description |
|---|---|
| `TOTAL(expr)` | Total for the partition (sum of all rows, regardless of position) |

**Percent of total:** `SUM([Sales]) / TOTAL(SUM([Sales]))`

### Model / Analytics Extensions

| Function | Description |
|---|---|
| `SCRIPT_REAL/INT/STR/BOOL` | Pass data to R or Python TabPy service |
| `MODEL_PERCENTILE(target, predictors)` | Probability that a value is ≤ the observed mark |
| `MODEL_QUANTILE(quantile, target, predictors)` | Target value at a specified quantile |
| `MODEL_EXTENSION_*` | Pass data to external analytics models |

### Pass-Through (RAWSQL)

Send SQL directly to the database without Tableau interpretation. Use `%n` as field substitution syntax (`%1` = first argument field, `%2` = second, etc.).

| Function | Description |
|---|---|
| `RAWSQL_INT("sql", [args])` | Integer from SQL expression |
| `RAWSQL_REAL("sql", [args])` | Float from SQL expression |
| `RAWSQL_STR("sql", [args])` | String from SQL expression |
| `RAWSQL_BOOL("sql", [args])` | Boolean from SQL expression |
| `RAWSQL_DATE("sql", [args])` | Date from SQL expression |
| `RAWSQLAGG_INT("sql", [args])` | Integer from aggregate SQL |
| `RAWSQLAGG_REAL("sql", [args])` | Float from aggregate SQL |

**Example:**
```
RAWSQL_REAL("DATEDIFF(day, %1, %2)", [Order Date], [Ship Date])
// Calls database-native DATEDIFF — useful when Tableau's date functions don't expose a needed feature
```

## Parameters

A parameter is a workbook variable (number, date, string, boolean) that substitutes into calculations, filters, reference lines, and set sizes.

**Creating:** Data pane → dropdown arrow → Create Parameter → set name, data type, allowable values (All / List / Range), and default value.

**Allowable values modes:**
- **All:** Simple text/number entry
- **List:** Predefined values; importable from a field or clipboard
- **Range:** Min, max, and step increment (not available for string type)

**Using parameters:**

In a calculated field:
```
IF [Sales] > [Min Sales Threshold] THEN "Above" ELSE "Below" END
// [Min Sales Threshold] is a parameter
```

In a Top N filter:
- Open the filter dialog → Top tab → "By field" → select the parameter as the N value

In a reference line:
- Analytics pane → drag Reference Line → Value dropdown → select the parameter

**Dynamic parameters:** A parameter can automatically refresh its current value from a field via a single-value FIXED LOD expression or a field-bound list/range. Refreshes on workbook open or data source refresh.

**Show parameter control:** Right-click parameter → Show Parameter. Display modes: slider, compact list, radio buttons, type-in field.

## Reference Lines & Bands

**Adding via Analytics pane:** Drag Reference Line, Reference Band, or Distribution into the view. Drop target highlights show available scope options.

**Scope:** Table (entire view), Pane (per pane), Cell (per cell).

**Reference Line configuration:**
- Value: Total / Sum / Constant / Minimum / Maximum / Average / Median, or a Parameter
- Label: None / Value / Computation / Custom (`<Field Name> = <Value>` syntax)
- Confidence interval shading: shade region where population average falls N% of the time

**Reference Distributions:**
- Percentages, Percentiles, Quantiles (3–10 tiles), Standard Deviation
- "Tableau uses estimation type 7 in the R standard to compute quantiles and percentiles"

**Box Plot via reference line:**
- Right-click a quantitative axis → Add Reference Line → Box Plot
- Shows IQR box + whiskers: 1.5× IQR (schematic) or maximum data extent (skeletal)
- Not available in web authoring

**Bullet graph pattern:**
- Add a distribution at 60% and 80% of the average of the detail measure for qualitative ranges
- Add a reference line at the target value
