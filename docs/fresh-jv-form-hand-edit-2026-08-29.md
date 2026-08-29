# Freshman & JV meals — live Google Form hand-edit (2026-08-29)

The generator (`scripts/create-fresh-jv-meals-form.gs`) only runs at form
CREATION. Re-running it makes a SECOND form. So the two texts below must be
pasted by hand into the live form:

<https://docs.google.com/forms/d/e/1FAIpQLSfUjMvPqXILNWVN1c_ivBbeZgigTlCMlHILFQyu0myWPydISw/viewform>

⚠️ Edit ONLY the form description and the help text under
"Which night(s) can you cover?". Do not touch the date checkbox options, and do
not add, delete, reorder or reword a question — `check-fresh-jv-meal-options.py`
compares the option strings, the sheet header row is the question titles, and the
prefill entry ids depend on question order.

The live form was fetched and parsed on 2026-08-29 and was still carrying BOTH
of the stale texts below. It is not only the time.

## What is wrong on the live form right now

1. **"We are still confirming the exact pickup time - plan on mid afternoon"** —
   in the description AND the date question's help text. The time was confirmed
   on 2026-08-26 and the form never got the hand-edit.
2. **"Bring it to the Horseshoe lot at McNeil. Coach Hale will meet you there.
   We confirm the drop-off spot by email the week of your night."** — this is the
   exact instruction that sent Debbie Reeves to the wrong place on 23 Aug. It was
   fixed in `lib/coach-meals.ts`, `lib/fresh-jv-meals.ts` and both Apps Scripts,
   and the COACH meals form was verified fixed on 2026-08-26. This form was
   missed. Every volunteer who has read this form since is reading the horseshoe.

## 1. Form description — replace the whole thing with:

On freshman and JV game nights the Booster Club feeds those players and coaching staffs. We need one volunteer per afternoon to collect the food and bring it to the school.

THE BOOSTER CLUB PLACES AND PAYS FOR THE ORDER. You are not ordering the food, choosing it, or paying for it. You pick up an order that is already placed and waiting.

Pick up from Bush's Chicken - North Austin at 12336 Ranch to Market Rd 620, Austin, TX 78750. Pickup is at 2:30 p.m. on the night you pick, and drop-off is right after, by 3:00 p.m.

Take it INSIDE the Player Drop-off Doors on the east side of the building, where Coach Hale will meet you. Not the horseshoe, and not the curb.

This is about 30 minutes of your time. We are truly grateful to all those that can assist.

Nights are first come first served. If someone beat you to one we will email you and tell you what is still open.

See what is still available at mcneilmavericks.org/boosters/fresh-jv-meals

## 2. Help text under "Which night(s) can you cover?" — replace with:

Pick up from Bush's Chicken - North Austin and bring it to the school. Pickup is at 2:30 p.m. on the night you pick, and drop-off is right after, by 3:00 p.m. Check as many nights as you can take. If a night is already claimed we will let you know and it will not count against the others you picked. Note September 23 is a WEDNESDAY.
