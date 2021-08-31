FORMATTER_OPTIONS = --header "" --swiftversion 5.5 --stripunusedargs unnamed-only --self insert --disable blankLinesAtStartOfScope,blankLinesAtEndOfScope --ifdef no-indent

format:
	swiftformat $(FORMATTER_OPTIONS) .