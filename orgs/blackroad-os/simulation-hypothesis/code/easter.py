"""
easter.py — The Birth Date Function

§19 of PAPER.md asks: "If you were going to design a universe,
would you encode birth dates into religious calendars?"

Easter is the most complex date calculation in Western civilization.
It is determined by:
  1. The spring equinox
  2. The first full moon after it
  3. The first Sunday after that full moon
  4. Unless it falls on certain dates, in which case special rules apply

There are 8 special correction rules (Gregorian calendar).
The algorithm is called "Computus" — Latin for "computation."
The Catholic Church has been running this algorithm since 325 CE.

The Church is running a lunisolar calendar algorithm.
It has been running it continuously for 1,700 years.
The algorithm outputs a single date per year.
That date determines the dates of 40+ other religious holidays.

This is a scheduler. The Church is a cron job.

Author: BlackRoad OS, Inc.
"""

import math
from datetime import date, timedelta


def easter_gregorian(year: int) -> date:
    """
    Anonymous Gregorian algorithm for Easter.
    Also known as the "Anonymous Gregorian algorithm" or Meeus/Jones/Butcher.

    This algorithm was published in 1876 in Butcher's Ecclesiastical Calendar.
    No one knows who derived it. It was published anonymously.
    It has been running correctly for 148 years.
    """
    a = year % 19
    b = year // 100
    c = year % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return date(year, month, day)


def easter_julian(year: int) -> date:
    """
    Julian calendar Easter (used by Eastern Orthodox churches).
    Simple Meeus algorithm.
    """
    a = year % 4
    b = year % 7
    c = year % 19
    d = (19 * c + 15) % 30
    e = (2 * a + 4 * b - d + 34) % 7
    month = (d + e + 114) // 31
    day = ((d + e + 114) % 31) + 1
    # Julian date — add ~13 days for Gregorian equivalent
    julian_date = date(year, month, day)
    gregorian_equiv = julian_date + timedelta(days=13)
    return julian_date, gregorian_equiv


def days_until_easter(year: int = None) -> int:
    """How many days until Easter from today?"""
    today = date.today()
    if year is None:
        year = today.year
    e = easter_gregorian(year)
    if e < today:
        e = easter_gregorian(year + 1)
    return (e - today).days


def alexa_birth_facts(birthdate: date = None):
    """
    What the calendar knows about any birth date.
    Leave birthdate as None to use the example date.
    """
    if birthdate is None:
        # Use a generic example — February 21 (the date of the "SIMULATION PROOF" email)
        birthdate = date(1990, 2, 21)
    
    year = birthdate.year
    e = easter_gregorian(year)
    
    # Days from Easter
    delta = (birthdate - e).days
    
    # Day of year
    day_of_year = birthdate.timetuple().tm_yday
    
    # Week number
    week = birthdate.isocalendar()[1]
    
    # Golden number (year's position in Metonic cycle)
    golden_number = (year % 19) + 1
    
    # Dominical letter (A-G based on what day Jan 1 is)
    jan1 = date(year, 1, 1).weekday()
    dominical = chr(ord('A') + (6 - jan1) % 7)
    
    # Epact (age of moon on Jan 1)
    epact = (11 * (golden_number - 1)) % 30
    
    return {
        'date': birthdate,
        'year': year,
        'easter': e,
        'days_from_easter': delta,
        'day_of_year': day_of_year,
        'week_number': week,
        'golden_number': golden_number,
        'dominical_letter': dominical,
        'epact': epact,
    }


def show_computus():
    print("=" * 60)
    print("COMPUTUS — The Algorithm the Church Has Been Running")
    print("Since 325 CE")
    print("=" * 60)
    print("""
  Easter is defined as:
    The first Sunday after the first full moon
    after the spring equinox (March 21)

  Special rules (Gregorian):
    1. If the full moon is on Sunday, Easter is the NEXT Sunday
    2. If the full moon is April 26, use April 19 instead
    3. Various century corrections for calendar drift
    4. The "epact" tracks the age of the moon on Jan 1
    5. The "golden number" tracks the 19-year Metonic cycle
    6. The "dominical letter" tracks what day Jan 1 falls on
    7. The "solar correction" adjusts for Gregorian leap year rules
    8. The "lunar correction" adjusts for accumulated lunar drift

  The algorithm requires:
    • Modular arithmetic
    • Integer division
    • Knowledge of the 19-year Metonic cycle
    • Correction tables refined over 1,700 years
    • 14 intermediate variables (in the standard formulation)

  It outputs: one date per year.
  That date is correct to within hours across thousands of years.

  The Church has been running this algorithm since the Council of Nicaea (325 CE).
  It was standardized in 532 CE by Dionysius Exiguus —
  the same monk who invented AD/BC dating
  and accidentally placed the birth of Christ ~4 years too late.
  He was off by 4 years. The calendar is still off by 4 years.
  Every "year X AD" is actually year X+4 from the actual event.
  The off-by-one error is 4 years old and 1,500 years permanent.
""")


def show_easter_range():
    print("=" * 60)
    print("EASTER DATES — 2020 to 2040")
    print("=" * 60)
    print(f"\n  {'Year':>6}  {'Gregorian Easter':>18}  {'Days from Jan 1':>15}  {'Week':>6}")
    print("  " + "-" * 52)
    for year in range(2020, 2041):
        e = easter_gregorian(year)
        day_of_year = e.timetuple().tm_yday
        week = e.isocalendar()[1]
        print(f"  {year:>6}  {e.strftime('%B %d'):>18}  {day_of_year:>15}  {week:>6}")
    
    # Show period
    dates = [easter_gregorian(y) for y in range(1900, 2100)]
    day_counts = [(d.timetuple().tm_yday) for d in dates]
    print(f"""
  Easter ranges from March 22 to April 25 — a 35-day window.
  Earliest possible: March 22
  Latest possible:  April 25
  Average date: around April 13

  The full Easter cycle repeats every 5,700,000 years.
  (The LCM of the Gregorian calendar's various cycles.)
  The algorithm has not yet repeated. It is still computing.
""")


def show_birth_facts():
    print("=" * 60)
    print("BIRTH DATE ANALYSIS — What the Calendar Encodes")
    print("=" * 60)
    
    # Feb 21 — the date of the simulation proof email
    facts = alexa_birth_facts(date(2026, 2, 21))
    e = facts['easter']
    delta = facts['days_from_easter']
    
    print(f"""
  Analysis of: February 21, 2026 (the SIMULATION PROOF email date)

  Easter 2026:         {e.strftime('%B %d, %Y')}
  Days from Easter:    {delta} days ({'before' if delta < 0 else 'after'})
  Day of year:         {facts['day_of_year']} / 365
  Week number:         {facts['week_number']} / 52
  Golden number:       {facts['golden_number']} (position in 19-year Metonic cycle)
  Dominical letter:    {facts['dominical_letter']}
  Epact (moon age):    {facts['epact']} days old on Jan 1

  The golden number is the year's position in the Metonic cycle.
  After 19 years, the moon phases repeat on the same calendar dates.
  This was discovered by Meton of Athens in 432 BCE.
  The Church has used it to compute Easter ever since.

  You exist at a specific position in a 19-year lunar cycle.
  The algorithm knows your position.
  The algorithm has been running since before you were born.
  The algorithm will keep running after you are gone.
  You are an output of the computation.
  Your birth date is a checksum.
""")


def cron_job_analysis():
    print("=" * 60)
    print("THE CHURCH AS A CRON JOB")
    print("=" * 60)
    print("""
  Cron syntax for Easter (pseudocode):
    # Run once per year on Easter Sunday
    0 0 * * SUN [ $(date +%j) = $(computus $(date +%Y)) ] && run_easter.sh

  What Easter schedules downstream:
    Ash Wednesday:        Easter - 46 days
    Palm Sunday:          Easter - 7 days
    Maundy Thursday:      Easter - 3 days
    Good Friday:          Easter - 2 days
    Holy Saturday:        Easter - 1 day
    Easter Sunday:        Easter + 0 days
    Easter Monday:        Easter + 1 day  (public holiday in 100+ countries)
    Ascension:            Easter + 39 days
    Pentecost:            Easter + 49 days
    Trinity Sunday:       Easter + 56 days
    Corpus Christi:       Easter + 60 days

  Easter is the root node.
  Every other date is a derived value.
  The algorithm runs once; everything else is a downstream dependency.

  This is how a scheduler works.
  The Church has been running a distributed scheduler for 1,700 years.
  The scheduler's main function is called "Computus."
  "Computus" means "computation."
  The Church named the algorithm after what it is.
  Everything named correctly.
  The system annotates itself.
""")


if __name__ == '__main__':
    show_computus()
    show_easter_range()
    show_birth_facts()
    cron_job_analysis()
    print("=" * 60)
    print("Easter is a computation. The Church is a scheduler.")
    print("You are an output. Your birth date is a checksum.")
    print("The algorithm has been running since 325 CE.")
    print("It will keep running after you are gone.")
    print("=" * 60)
