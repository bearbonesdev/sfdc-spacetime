# Spacetime

Spacetime is a simple utility class which aims to simplify dealing with timezones
in Apex.

## Background

Dates and Times are easy to work with. When you try combining the two, such as in
a Datetime, things get more complicated. A Datetime either uses the context of the user
setting the value to convert from the user's timezone to gmt, or requires the user to
explicitly set a gmt value.

Spacetime solves this problem by keeping the date and time separate and requiring an
explicit timezone to use. Then, when necessary, it handles the conversion to/from a
datetime value.

An instance of Spacetime is by design immutable since any change would make it
in fact a different Spacetime. All _setter_ methods thus return a new instance.

## Basic usage

```apex
	Timezone tz = Timezone.getTimeZone('America/New_York');
	Date d = Date.newInstance(2000,1,1);
	Time t = Time.newInstance(12,30,0,0);

	Spacetime st = Spacetime.newInstance(tz,d,t);

	// 12:30 PM in EST is 17:30 in GMT
	Assert.areEqual(
		'2000-01-01T17:30:00.000Z',
		st.toISOString()
	);
```

## Timezone conversions

```apex
	Timezone tz = Timezone.getTimeZone('America/New_York');
	Date d = Date.newInstance(2000,1,1);
	Time t = Time.newInstance(12,30,0,0);

	Spacetime EST = Spacetime.newInstance(tz,d,t);

	// 12:30 PM
	Assert.areEqual(
		'12:30:00.000Z',
		EST.time().toString()
	);

	Timezone targetTz = Timezone.getTimeZone('America/Los_Angeles');
	Spacetime PST = EST.convertTo(targetTz);

	// 09:30 AM
	Assert.areEqual(
		'09:30:00.000Z',
		PST.time().toString()
	);

	// underlying gmt time is unaffected
	Assert.areEqual(
		EST.toISOString(),
		PST.toISOString()
	);
```

## Loading from a Datetime value

You can initialize a Spacetime instance from a Datetime value as well, but note
that it is expected that the Datetime value is of correct GMT time. If you have
users modifying datetime fields from a standard page layout, the entry is in their
timezone, not necessarily the context of the record. This can lead to the database
holding datetimes which are "Business Wall-Time" and not always accurate GMT time.

```apex
	Timezone tz = Timezone.getTimeZone('America/New_York');
	Datetime dt = Datetime.newInstanceGMT(2000,1,1,12,30,0);

	Spacetime st = Spacetime.newInstance(tz,dt);

	Assert.areEqual(
		'07:30:00.000Z',
		st.time().toString()
	);
```
