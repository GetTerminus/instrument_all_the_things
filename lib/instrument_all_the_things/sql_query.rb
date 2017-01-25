module InstrumentAllTheThings
  module SQLQuery
    include HelperMethods
    class << self
      def record_query(table: nil, action: nil, sql: nil, duration:)
        derived = parse_query(sql) unless table && action
        table ||= derived[:table]
        action ||= derived[:action]

        tags = [
          "sql_table:#{normalize_class_name(table)}",
          "sql_action:#{normalize_class_name(action)}"
        ]

        with_tags(tags) do
          increment("sql.queries.count")
          timing("sql.queries.timings", duration)
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
        when /^\s*INSERT INTO\s+"?([^" ]+)"?/i
          {action: "insert", table: $1.downcase}
        else
          {action: 'unknown', table: 'unknown'}
        end
      end
    end
  end
end
