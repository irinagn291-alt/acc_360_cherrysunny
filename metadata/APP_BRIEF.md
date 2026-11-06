<!-- gf-brief source=3eece917ac81d87a6801f9782e0f2021b12bac20504ab776a43cb88cc5ed4fef written=2026-11-07T01:40:34+03:00 -->
# CherrySunny

## What it is

CherrySunny is a food journal for people who want to record portions and review nutrition totals from food labels. Users can find packaged foods, enter the amount eaten and meal, and review a day or week.

## Launch and onboarding

A cold launch opens the journal on today’s date with “Day” selected. There is no onboarding.

On a fresh install, the screen shows “CherrySunny”, “A little note for every meal”, “Your daily food journal”, “What’s on your plate?” and “Pick a food and enter your portion to start the day’s journal.” The main button is “Log your first portion”; at larger accessibility text sizes it reads “Add a portion”. Under “Meal entries”, “Breakfast”, “Lunch”, “Dinner” and “Snack” each show “No portions yet”.

## Screens

### Journal: “Day”

- “Day” and “Week” switch between the daily journal and weekly review.
- The displayed date opens “Journal date”. “Choose date” selects today or an earlier date, and “Done” closes the calendar. The arrow controls, accessible as “Previous day” and “Next day”, move between dates.
- “Log your first portion” or “Add a portion” opens “Food catalog”.
- Once entries exist, the daily card shows “Daily energy”, the energy value and “kcal logged”, plus “Protein”, “Carbs” and “Fat”. “— no label data · ≥ partial total” explains missing values when applicable.
- “Log it again” offers up to six recently logged foods. Tapping a food opens a new portion for that product.
- “Meal entries” groups portions under “Breakfast”, “Lunch”, “Dinner” and “Snack”. Tapping a logged food opens “Journal entry” to edit or delete it.
- “Daily nutrition” shows “Energy”, “Protein”, “Fat”, “Carbs”, “Fiber”, “Sugars” and “Salt”. Where applicable, it explains: “≥ marks a partial total. A dash means the nutrient is missing from every label.”

### Journal: “Week”

The selected week is headed “Week in review” and “Energy · seven days”, followed by “Your week in food”. The date opens “Journal date”; the arrows are accessible as “Previous week” and “Next week”.

The seven day columns show energy from available labels. Tapping an available day opens that day in “Day”. The screen also shows “Days logged” and “Portions this week”. When the week has entries, “Weekly nutrition” shows the seven nutrient totals and “Daily entries” lists logged days; tapping a day opens it. The chart explains: “Energy from available labels. Tap a column to see the day.”

### “Food catalog”

The screen says “A note starts here”, “Find your food” and “Search a label or scan the package.”

- “Name, brand or barcode” accepts a query. “Clear” clears it; submitting the keyboard search or tapping “Search online” searches Open Food Facts.
- “Scan” opens “Barcode”.
- “Search results” lists online matches. “Available offline” lists matching starter products and previously opened labels when there are no online results. A product row shows its name, brand when available, and barcode; tapping it opens “New portion”, after retrieving the full label when needed.
- “Close” returns to the journal.
- “Open Food Facts · community data”, “Database license · ODbL” and “Photo license · CC BY-SA” open their respective sources. The screen says: “Recipes can change. Check the printed package for current ingredients.”

### “Barcode”

The camera scans a supported package barcode and returns it to the catalog for lookup. “Close” returns to the catalog. If scanning is unavailable, “Scanner unavailable” offers “Type a barcode”; when camera access was denied, “Open Settings” is also offered.

### “New portion” and “Journal entry”

The editor shows “FOOD LABEL”, the product name and available brand. “View food label” opens the product’s source.

- “Portion size” accepts an amount in “g” or “ml”. Preset buttons offer “50”, “100”, “150” and “250” in the product’s unit.
- “Meal” selects “Breakfast”, “Lunch”, “Dinner” or “Snack”. A new entry initially uses a meal based on the time of day.
- “Date” selects today or an earlier date.
- “In this portion” shows the nutrient amounts calculated for the entered portion.
- “Log portion” saves a new entry; “Save changes” saves an existing entry. At larger accessibility text sizes, the visible button reads “Save”.
- “Close” dismisses the editor without saving. The keyboard’s “Done” dismisses the keyboard.
- For an existing entry, “Delete entry” opens “Delete this portion from your journal?” with “Delete portion” and “Cancel”.

### Home Screen widget: “Today’s portions”

The small and medium widgets show today’s summary; the medium widget can also show the latest portion. The widget description is “Your daily nutrition totals and latest portions.” Tapping it opens today’s “Day” journal.

## Features

- Find foods in “Open Food Facts” by name, brand or barcode, or use “Available offline”.
- “Scan” a supported food-package barcode.
- Record a “Portion size”, “Meal” and “Date”; edit or delete a “Journal entry”.
- Use “Log it again” for recently logged foods.
- Review “Daily nutrition”, “Weekly nutrition”, “Daily entries”, “Days logged” and “Portions this week”.
- View “In this portion” before saving.
- Open the source with “View food label”.
- See today’s portions in the “Today’s portions” widget.

## Behaviours that can look like bugs

- “Log your first portion” is disabled while the journal loads. If reading fails, “Journal unavailable” says “Your journal could not be read. Close and reopen the app to try again.”
- “Search online” is disabled for an empty query and while a search is running. Enter a name, brand or barcode and wait for the current search to finish.
- An all-numeric query outside 4–14 digits shows “Check the barcode digits on the package.” Correct the digits.
- A search can show “No matches. Try another name or scan the barcode.” Other possible messages are “Too many searches. Wait a minute or choose a saved product.”, “The catalog returned an unreadable product. Please try again.”, “Open Food Facts does not have this barcode yet.” and “Open Food Facts is unavailable. You can still use the offline catalog.”
- If a full label cannot be opened, “Full label unavailable” says “You can use the saved or indexed information now. Some fields may be missing.” Choose “Use available information” or “Cancel”.
- If the scanner cannot be used, its message may say “Type the barcode from the package on this device.”, “Type the barcode or check camera access in Settings.” or “The camera is unavailable. Type the barcode from the package into the search field.” Use “Type a barcode” and enter it in the catalog; “Open Settings” is available after camera access is denied.
- “Log portion” and “Save changes” are disabled for an invalid amount. The editor says “Enter a portion from 0.1 to 10,000 g.” or “Enter a portion from 0.1 to 10,000 ml.” Enter a value in that range or choose a preset.
- Future dates cannot be selected. “Next day” is disabled on today, “Next week” is disabled in the current week, and future columns in the weekly chart are disabled.
- An empty week says “No entries this week. Choose a day to log a portion.” Select a day and add a portion.
- “Available offline” grows as labels are opened; “Log it again” appears after logging foods and shows up to six recently logged products.
- Missing nutrition data is shown as a dash; “≥” marks a partial total. Opening the printed package or “View food label” may provide more information.
- A failed save or delete shows “Couldn’t save this entry” and “Your changes could not be saved. Try again.” Tap “Close” and retry.

## Starter content and resume

A fresh journal has no seeded meal entries. “Available offline” includes starter products: “Weetabix”, “Spaghetti Nº5”, “Crispy minis chocolate chip”, “Fibres”, “Barilla PESTO alla GENOVESE” and “Alpen Original Muesli”.

Saved entries remain available after reopening and can be edited. An unsaved portion is not resumed after its editor is closed.

## Permissions

Camera access is requested when “Scan” is opened on a supported device. The usage description is: “Scan a food package barcode to find its product in Open Food Facts.”

## Absent

Login or accounts, in-app purchase, ads, analytics, an account deletion flow and an App Tracking Transparency prompt are absent. Users create journal entries, but there is no user-generated content publishing or sharing flow.

## Data and support

Journal entries and opened product labels are stored on the device. Online searches send the entered query to Open Food Facts, and the app can open external product and attribution links. Today’s summary is shared locally with the Home Screen widget.

There is no on-screen Contact or Support control.

## Scanning and health

The app scans EAN-13, EAN-8 and UPC-E food-package barcodes for product lookup. It does not scan QR codes.

It displays food-label nutrition values and calculated portion, daily and weekly totals. The product source is available through “View food label”; the catalog also links “Open Food Facts · community data” and the data and photo licenses. The app does not display medical advice.

## Platform

The interface and date formatting use English with US formatting; weeks start on Monday. Online text search requests English results, and the catalog is not restricted to a particular storefront region.

The app supports iPhone and iPad on iOS 17.0 or later. iPhone supports portrait and both landscape orientations; iPad also supports upside-down portrait.

## Category

Health & Fitness.
