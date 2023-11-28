require 'sequel'
require 'sequel/adapters/jdbc'

Sequel.database_timezone = :utc
Sequel.typecast_timezone = :utc

# Test our DB connection and load the JDBC driver.
Sequel.connect(AppConfig[:db_url]) do
end

connector_version = if (com.mysql.cj.jdbc.Driver rescue nil)
                      puts "Detected MySQL connector 8+"
                      :new
                    else
                      puts "Detected legacy MySQL connector (5.x)"
                      :legacy
                    end


# Set our timezone to UTC to prevent the JDBC driver from adjusting our dates.
if connector_version == :new
  jdbc_url = AppConfig[:db_url]

  if jdbc_url =~ /serverTimezone=/ && jdbc_url !~ /serverTimezone=UTC/
    raise "The 'serverTimezone' parameter must be set to UTC in AppConfig[:db_url]."
  end

  if jdbc_url !~ /serverTimezone=UTC/
    jdbc_url += "&serverTimezone=UTC"
  end

  AppConfig[:db_url] = jdbc_url
end


if connector_version == :new
  class Sequel::JDBC::Database
    def timestamp_convert(r, i)
      if v = r.getTimestamp(i)
        # When serverTimezone=UTC, timestamps coming out of MySQL will return a correct
        # epoch time when `.getTime()` is called, but will otherwise be expressed in the
        # JVM's default timezone.  For example, if your timestamp was midnight UTC,
        # `timestamp.getHour()` might return 20 if you were in New York (and four hours
        # behind UTC).
        #
        # Sequel is configured to use the UTC timezone too, but
        # `to_application_timestamp` is expecting to get
        # year/month/day/hour/mins/seconds in UTC values, not in local time values.
        #
        # To make these things line up, get a Calendar instance corresponding to `v` in
        # the UTC timezone and then read off the UTC values.
        #
        # Fun note: you might think you could just set serverTimezone to match your
        # JVM's timezone and avoid this whole mess, and that's also the default if you
        # don't specify serverTimezone at all.  That gets into trouble around the DST
        # switch, though: your database ends up storing a UTC timestamp around 2am on
        # the second Sunday in March, which is valid for UTC but not valid for your
        # local timezone.  The MySQL driver tries to load it into a timezoned value, and
        # you get the dreaded:
        #
        #    Sequel::DatabaseError: Java::JavaSql::SQLException: HOUR_OF_DAY: 2 -> 3

        cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"))
        cal.setTimeInMillis(v.get_time)

        to_application_timestamp([cal.get(java.util.Calendar::YEAR),
                                  cal.get(java.util.Calendar::MONTH) + 1,
                                  cal.get(java.util.Calendar::DATE),
                                  cal.get(java.util.Calendar::HOUR_OF_DAY),
                                  cal.get(java.util.Calendar::MINUTE),
                                  cal.get(java.util.Calendar::SECOND),
                                  cal.get(java.util.Calendar::MILLISECOND) * 1_000_000, # nanoseconds
                                 ])
      end
    end
  end
end
