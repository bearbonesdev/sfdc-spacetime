/**
 * copyright (c) 2026 BearBonesDev
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/soql-lib/blob/main/LICENSE)
 *
 * @version 0.5.0
**/
public class Spacetime implements Comparable{
	public static final Integer MS_PER_SECOND = 1000;
	public static final Integer MS_PER_MINUTE = MS_PER_SECOND * 60;
	public static final Integer MS_PER_HOUR = MS_PER_MINUTE * 60;

	private Date d;
	private Time t;
	private final TimeZone tz;

	private SpaceTime(
		TimeZone timezoneValue,
		Date dateValue,
		Time timeValue
	){
		if(timezoneValue == null) throw new IllegalArgumentException('timezoneValue is required.');
		if(dateValue == null) throw new IllegalArgumentException('dateValue is required.');
		if(timeValue == null) throw new IllegalArgumentException('timeValue is required.');

		this.tz = timezoneValue;
		this.d = Date.newInstance(dateValue.year(),dateValue.month(),dateValue.day());
		this.t = Time.newInstance(timeValue.hour(),timeValue.minute(),timeValue.second(),timeValue.millisecond());
	}

	// accessors
	public Time time(){
		return this.t;
	}

	public Date date(){
		return this.d;
	}

	public TimeZone timezone(){
		return this.tz;
	}

	public String timezoneId(){
		return this.tz.getId();
	}

	/**
	 * get unix timestamp
	 */
	public Long getTime(){
		return this.toDatetime().getTime();
	}

	public Integer year(){
		return this.d.year();
	}

	public Integer month(){
		return this.d.month();
	}

	public Integer day(){
		return this.d.day();
	}

	public Integer hour(){
		return this.t.hour();
	}

	public Integer minute(){
		return this.t.minute();
	}

	public Integer second(){
		return this.t.second();
	}

	public Integer millisecond(){
		return this.t.millisecond();
	}

	/**
	 * returns a DateTime instance for the spacetime where the underlying GMT
	 * value is correct for the supplied timezone context.
   */
	public Datetime toDateTime(){

		Integer offsetSeconds = this.tz.getOffset(this.d) / MS_PER_SECOND;

		return Datetime.newInstanceGmt(this.d,this.t).addSeconds(-offsetSeconds);

	}
	public String toISOString(){
		return this.toDatetime().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
	}

	public String format(
		String dateFormatString
	){
		return this.toDateTime().format(dateFormatString,this.timezoneId());
	}

	public override String toString(){

		return this.toDatetime().toString();
	}

	public override Integer hashcode(){
		Integer hash = 17;

		hash = hash * 31 + this.d.hashcode();
		hash = hash * 31 + this.t.hashcode();
		hash = hash * 31 + this.tz.hashcode();

		return hash;
	}

	/**
   * get a new spacetime instance for this same moment in another timezone
	 */
	public Spacetime convertTo(Timezone timezoneValue){
		return newInstance(timezoneValue, this.toDatetime());
	}

	/**
	 * two spacetimes are equal only if they are equal in both space AND time. if
	 * you wish to only compare the time component, generate datetime values or
	 * iso strings first.
	 */
	public Boolean equals(Object obj){
		return obj instanceof SpaceTime &&
			obj.hashcode() == this.hashcode();
	}

	public Integer compareTo(Object obj){
			Spacetime that = (Spacetime)obj;

			Long thisUnix = this.getTime();
			Long thatUnix = that.getTime();

			return (thisUnix - thatUnix).intValue();

	}
	public Spacetime addYears(Integer years){
		return new Spacetime(
			this.tz,
			this.d.addYears(years),
			this.t
		);
	}

	public Spacetime addMonths(Integer months){
		return new Spacetime(
			this.tz,
			this.d.addMonths(months),
			this.t
		);
	}

	public Spacetime addDays(Integer days){
		return new Spacetime(
			this.tz,
			this.d.addDays(days),
			this.t
		);
	}

	public Spacetime addHours(Long hours){
		return this.addMilliseconds(hours*MS_PER_HOUR);
	}
	public Spacetime addMinutes(Long minutes){
		return this.addMilliseconds(minutes*MS_PER_MINUTE);
	}
	public Spacetime addSeconds(Long seconds){
		return this.addMilliseconds(seconds*MS_PER_SECOND);
	}
	public Spacetime addMilliseconds(Long milliseconds){
		Long unix = this.toDateTime().getTime();
		unix += milliseconds;

		Datetime gmtDt = Datetime.newInstance(unix);

		return newInstance(this.tz,gmtDt);
	}

	public static Spacetime newInstance(Timezone timezoneValue, Date dateValue, Time timeValue){
		return new Spacetime(timezoneValue,dateValue,timeValue);
	}
	public static Spacetime newInstance(String timezoneId, Date dateValue, Time timeValue){
		return newInstance(Timezone.getTimeZone(timezoneId),dateValue,timeValue);
	}

	public static Spacetime newInstance(Timezone timezoneValue, Datetime datetimeValue){
		// based on the tz, the offset may change the date of datetimeValue. this,
		// in effect, can change the offset.

		Date d = datetimeValue.dateGMT();
		Time t = dateTimeValue.timeGMT();

		Integer offsetMilliseconds = getNormalizedOffset(timezoneValue,d,t);

		Integer offsetSeconds = offsetMilliseconds / MS_PER_SECOND;

		Datetime adjusted = datetimeValue.addSeconds(offsetSeconds);

		Date adjustedDate = adjusted.dateGMT();
		Time adjustedTime = adjusted.timeGMT();

		return newInstance(timezoneValue,adjustedDate,adjustedTime);
	}

	public static Spacetime newInstance(String timezoneId, Datetime datetimeValue){
		return newInstance(Timezone.getTimeZone(timezoneId),datetimeValue);
	}

	/**
   * get time as ms since midnight.
	 */
	public static Integer timeToMilliseconds(Time timeValue){
		Integer ms = timeValue.millisecond();
		ms += timeValue.second() * MS_PER_SECOND;
		ms += timeValue.minute() * MS_PER_MINUTE;
		ms += timeValue.hour() * MS_PER_HOUR;

		return ms;
	}

	/**
   * get the local offset of the provided date and time, considering that the
   * offset can changed based on the date. offsets are calculated relative to
   * the timezone location, not gmt.
   *
   * TODO: for now, we ignore that time changes happen at a specific hour and
   * can lead to skipped or repeated hours. this will be addressed in a later
   * release.
   */
  @TestVisible
	private static Integer getNormalizedOffset(Timezone tz, Date gmtDate, Time gmtTime){
		Integer msSinceMidnight = timeToMilliseconds(gmtTime);
		Integer offsetMilliseconds = tz.getOffset(gmtDate);

		Date d = gmtDate;
		if (offsetMilliseconds > 0 &&
			offsetMilliseconds + msSinceMidnight > MS_PER_HOUR * 24
		){
			d = d.addDays(1);
		} else if (offsetMilliseconds < 0 &&
			offsetMilliseconds  + msSinceMidnight < 0
		){
			d = d.addDays(-1);
		}

		return offsetMilliseconds;
	}

}
