# Supported platforms

CherrySunny supports iPhone and iPad only, with an iOS Home Screen widget.
Apple Watch support was explicitly removed at the user's request. Do not add a
watchOS target, an embedded Watch app, WatchConnectivity, or Watch marketing claims.
Keep this restriction when regenerating project.yml or preparing store metadata.

Before delivery, inspect the archive or IPA to confirm that it contains no Watch
app, watchOS bundle, or WatchKit keys. Retain the existing iOS bundle identifiers
and shared widget storage so existing data remains compatible.
