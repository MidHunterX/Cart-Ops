# Thought Processes

## What is this project?

People shopping at the mall faces a common problem especially with a specific
budget in mind, it's hard to keep track of how much is being spent and how much
of the budget is remaining. This is a shopping calculator which is meant to be
used while shopping to actively track your running totals on how much you have
spent so far. Allows you to enjoy the shopping experience, spending your focus
on the products only instead of running costs at all time.

## Why was this created?

> Before going down the path of re-inventing a wheel, you have to look into the
> paths of the people who came before us.

There are many shopping calculators out there in the market. Almost all are
proprietary. Reviews commonly complain about features hidden behind a paywall
and ads. Many of them tries to do too many things at once; achieving the
mediocre out of all worlds due to the lack of focus.

> Find the best of the best and improve upon it.

`Shopping Calculator` by LemonClip offers an intuitive interface where you can
tab out to next entry, so that you don't have to reach out to select the next
input; always keeping your hand on the keyboard. One of the best and efficient
UX. But the features are bit too simple for personal preferences. Philosophy
focus on solving the spontaneous problem at present efficiently.

Since it's spontaneity focused, the problem here is **planning**.

The generic Shopping calculators which represents the majority in the market
tries to solve this. By giving separate interfaces for Shopping list and
Running price tracker. But what if I am planning for a purchase which I want
the running price as well? In a single interface?. This is solved elegantly by
the next product.

`Shopping Calculator` by MLZ allows you to create everything immediately with
zero input at minimum. Add a shopping event with default placeholder name. Add
bought items with price only. Add extra details later down the road. This
freedom allows the maximum amount of flexibility.

One standout observation: This app uses Telephone Style Keypad UI. This means,
the developer probably finds Telephone Style comfortable than Calculator Style.

- Plan a shopping list? Add items with Names and maybe with units and weights.
- Need to attach extra details? Add those in the same interface.
- Want a running tracker? Add units/weight along with price in the same UI.
- Made a mistake? Long press on any of the details visible on screen.
- Items are irrelevant, just need to add money entries? Just add prices.

The focus is similar to UNIX philosophy:

> Do one thing and do it well.

This solves every single problem of general population. The flexibility allows
accommodating people with different styles of thought processes. But what if I
want to group all of those purchases? If I am shopping from a specific store
and I want to group all of those purchases separate from the other purchases?

Since this is proprietary and closed source, I cannot take it and modify it for
myself and I'll have to depend on the developer to implement all of those
features.

## Re-Inventing a better wheel

### 📱 Main Screen

Dynamically shows Purchases/Groups list based on intent and behavior.

#### Split Screen

If both groups and ungrouped purchases are present, the main screen is divided
into two sections:

##### Groups

A horizontally scrollable list of created groups. Each group have it's own
separate item autocompletion and purchases list. With this you can track prices
of items from one store to another. This is for those people who wants to
organize their shopping.

##### Purchases

Clicking `Add purchase` Creates a new purchase event with 'Purchase' as
default name along with current date and time then immediately takes you into
the next interface, ready to add Purchased Items. This is for those spontaneous
people who just wants to create purchased items right now.

#### Dedicated Screen

If only one of the groups or ungrouped purchases are present, the main screen
turns into a dedicated screen for the respective list. If only groups is
present, group specific details and a big grid view will be shown. If only
ungrouped purchases is present, a list view will be shown.

### 📃 Purchased Items List

On adding items to a purchase, every single attribute is optional for spontaneity.

- Weight/Unit
- Item Name
- Item Price per Unit
- Image
- Discount

Items Style can be toggled in settings. There are two options:

#### Dynamic List

This list style is meant to latch on to the 'Mere-exposure effect' for
cognitive familiarity by designing item entry in a way similar to school
mathematics `Items x Price = Total Price`.

So for each item, the UI is composed of three parts: Unit, Price and Total.

In Items Section (Left Side), Items or Weight is shown based on the entry. If
not present, a button is shown to add weight or unit.

Price Section (Next to Unit Section) shows the **price** with more emphasis to
read as `Items x Price`. For example, 2 units of amt 10 is 20. But if the
name is provided, **name** overrides the emphasis to read as: 2 Lemon cost 20.
Following 'Gestalt Proximity Principle', the price will be under the name as
it's the cost of the item Lemon. Image is also optionally shown next to name.

Total Section (Right Side) shows the **total** as right aligned. This is the
standard for calculations. If per item price is not set, a button to input is
shown here instead of price section. Because this section cannot exist without
a per item price and also for balancing composition.

#### Structured List

This style is for people who prefers a structured, organized and predictable
environment. Every single item attribute have a dedicated place in the UI. This
keeps everything predictable. If you want to look for something, you'll know
where it is exactly; catering to ASD like neuro-types. But the Dynamic List
reduces the visual noise to the maximum so, sticking to self selected
attributes only helps not breaking the pattern.

### 📜 Checklist Mode

Purchased Item List can be toggled into Checklist Mode. In this mode, you can
reuse the same interface for:

- Using list as a grocery list and toggling items as completed
- Toggle list to check how much each set of items cost together
- Find how much lesser the total cost would be without certain items

### 🔧 Settings

- **Theme Mode**: Light Mode | Dark Mode | System (Default)
  - Respect user's choice first for not breaking the cohesion.
- **Theme Color**: Material Colors: green, blue (Default), red, orange, purple, teal, pink
  - In Color Semiotics, Blue is associated with Trust, Stability etc. For early
    humans, a clear blue sky meant safety and predictable weather. Which is the
    reason why banks use it often.
- **Currency**: All Currencies around the World
  - Currency is detected from device region. Fallback to USD if not found.
- **Weight Unit**: Kg (Default) | Lb
- **Dynamic Item List**: On - Dynamic List (Default) | Off - Structured List
- **Dominant Hand**: Right (Default) | Left | Ambidextrous
  - Right Hand is the most common dominant hand.
- **Keypad Layout**: Calculator (Default) | Telephone
  - There are people who are much more accustomed to a each keypad. Cognition,
    history and muscle memory play a major role in this.

#### Keypad Layout

When it comes to keypad layouts, there are mainly two paradigms:

- Bottom-Up (`7 8 9 - 4 5 6 - 1 2 3 - 0`): Personal Computer Keyboards and
  Calculator uses this style of keypad layout.
- Top-Down (`1 2 3 - 4 5 6 - 7 8 9 - 0`): Telephones, ATMs and modern
  Smartphones uses this style of keypad layout.

People like CPAs/Accountants who use keyboards and calculators on a daily basis
might find the unexpected Top-Down number pad jarring due to muscle memory. The
same narrative goes to phone users as well.

##### Keypad Haptics

Keypad is where all of the most important work is being done in this workflow.
Taking price, weight, discount inputs without some kind of feedback makes our
mind actively try to spend more time in visual confirmation on input fields.
Proper haptic feedback is essential for a much smoother input-feedback loop.

### 📁 Empty Screens

Especially when there are multiple screens, Navigating through fully empty
screens can cause confusion. Which is why pages often have empty messages or
placeholders. How you word and present the message can influence user's
thoughts which in turn influences the behavior and feeling.

- Purchases Screen: When purchase screen is empty, It must have a positive tone
  about no purchase being made _yet_ (anticipation and slightly defensive about
  spending financial resources).
- Item List Screen: When list is empty, do not judge users for having an empty
  cart/list. It leaves a bad taste. Instead showing "Your Cart is Ready! - Add
  items to ..." respects and acknowledges users decision to make the purchase
  event.

### 🛒 Discounts

Aside from dedicated budget tracking software, this is the area where almost
all of the implementation falters. Many apps don't bother even adding one.
Following the philosophy that everything is merely an item with a price.

But what if you want to track discounts and the actual selling price? This is
where things get tricky. Mainly there are three options:

- Percentage: Reduces the price by a certain percentage.
- Price: Reduces the price per unit by a certain amount.
- Offer: Reduces the total price by a fixed amount. (Can be combined)

Offer is an abstract reusable pattern which can be used for different discount
mechanisms like Coupons, Buy N Get N Free, Free Samples, Concessions etc.

The optimal way to implement generally is by:

| Column | Type                        |
| ------ | --------------------------- |
| type   | ENUM('PERCENTAGE', 'FIXED') |
| value  | DECIMAL(10,2)               |

But this app is all about doing heavy crud operations around calculations where
values changes constantly. So, percentage should be the only source of truth.
This way, the discount scales correctly with price corrections.

#### Discount Entry UX Problem

Almost everywhere there is a discount entry field, it would just be an input
given for fixed price or percentage. The problem is in real world, prices would
be like: `[~Listing Price~ Selling Price]` than fixed values most of the
time. This makes users to do mental calculation to figure out the discount
amount per unit weight, creating unnecessary cognitive load.

The best way is to give a dedicated discount calculating utility as input:

- Price: `[Listing Price] - [Discount] = [Selling Price] per unit`
- Percentage: `[Listing Price] x [Percentage]% = [Selling Price] /unit`

Where three input fields can be edited and calculated in real time.

### 🚀 User Onboarding

If there are many features shown all at once, there's high chance of
experiencing cognitive friction since you have to find out the primary
objective and how everything works.

To solve this, the most commonly used strategy is user onboarding animations.
Showing people what each and everything does and how it works. Or maybe even
forcing you to go through the workflow for one time. Sometimes even wasting
your time. But, if done correctly, it can be very effective.

User onboarding is plain simple naturally following the principle of
**Progressive Disclosure**.

1. At first it will be just a simple app. There's a button to add purchase
   event which automatically sets up everything just ready to receive
   purchases. Type item name > price > add. View running totals nothing more.
2. On second purchase event, upon adding items, you type the item name as usual
   but what's this? There's now a dropdown with the item names. Click on it and
   every information including name, price, discount and image is auto-filled
   for you. Only input quantity this time + other corrections if any. Nice
3. On third purchase event, you auto-complete items as usual. Now what's this..
   Since this is the third time an item is purchased, a price history graph
   pops up on top of the keypad. Now you have a bird's eye view of the item's
   pricing fluctuations and trends over time.
4. You can go to settings and enable groups feature to enable purchase groups
   only if you want.

## Problems Faced :(

### Power User UI for Price Inputs?
