module InstrumentAllTheThings
  module SQLQuery
    class << self
      def record_query(table: nil, action: nil, sql: nil, duration:)
        derived = parse_query(sql) unless table && action
        table ||= derived[:table]
        action ||= derived[:action]

        tags = [
          "table:#{InstrumentAllTheThings.normalize_class_name(table)}",
          "action:#{InstrumentAllTheThings.normalize_class_name(action)}"
        ]

        InstrumentAllTheThings.with_tags(tags) do
          InstrumentAllTheThings.transmitter.increment("sql.queries.count")
          InstrumentAllTheThings.transmitter.timing("sql.queries.timings", duration / 1000.0)
        end
      end

      def parse_query(query)
        case query
        when /^\s*SELECT\s+COUNT\(.*\)\s+FROM "?([^" ]+)?"?/i
          {action: 'count', table: $1.downcase}
        when /^\s*SELECT\s+.*\s+FROM "?([^" ]+)?"?/i
          {action: 'select', table: $1.downcase}
        when /^\s*(UPDATE|DELETE)(?:\s+FROM)?\s+"?([^" ]+)"?/i
          {action: $1.downcase, table: $2.downcase}
        else
          {action: 'unknown', table: 'unknown'}
        end
      end
    end
  end
end
