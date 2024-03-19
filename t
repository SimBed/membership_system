* [33mdefca9c[m[33m ([m[1;36mHEAD -> [m[1;32mmaster[m[33m)[m reformat routes (stage2)
[31m|[m * [33m97460e7[m[33m ([m[1;32mmorerouting[m[33m)[m routing (stage4)
[31m|[m * [33m4d67c2a[m reformat routing (stage3)
[31m|[m * [33m562b9b7[m reformat routing (stage 2)
[31m|[m[31m/[m  
* [33m5e15924[m[33m ([m[1;31morigin/master[m[33m, [m[1;31mheroku/master[m[33m)[m add discount reason rationale to the list of discount reasons when creating new discount (to avoid ambiguity when names are the same eg renewal after expiry (renewal) [x%] and renewal after expiry (discretionary) [y%]
* [33m86869f4[m reformat routes (stage1)
* [33m816d8c9[m implement superadmin can delete accounts through UI
* [33m9800dfc[m add confirmation message with stimulus to blast messages button
* [33md57b3a6[m add max recipient limit for blast
* [33m00492dd[m show payment details in purchase show
* [33m3ff30fb[m hotfix purchase.payment to purchase.charge in client pt discount
* [33m99aee8b[m hotfix blast greeting
* [33m2709d79[m add boss as recipient to message blast test
* [33me99d6fb[m download payment data for accountant
* [33m9e15f00[m add filters to payments index
* [33m20d428f[m abstract payment details from purchase model
* [33m1ee45df[m change purchase attribute name payment to charge, in preparation for abstraction
* [33m362fbd9[m hotfix error when create adjustment with empty amount
* [33m9711704[m hotfix edit freeze without payment
* [33m5cd386b[m implement message blast
* [33mb3cab7b[m change homepage picture
* [33mcd53aec[m hotfix clientanalyze fail (when rider has unexpired main). Amendment to Purchase#expired_on.
* [33m2a0cbc2[m give access to individual payments to junioradmin
* [33m58bfa03[m add filter to payments index
* [33m1021e4f[m link payment from freezes index, rename restart-parent/child, rename residual references to Adjust & Restart
* [33m0089237[m add period filter to freezes index
* [33m748df50[m add restart warning method and associated formatting
* [33mb759797[m update policy docs for renaming of Adjust & Restart; improve restarts index
* [33m079c45e[m test freeze edit; hotfix freeze form payment amount on edit; link on type on payments index
* [33m938588c[m expand payments controller methods, enhance links between purchase show and payable
* [33mb79a059[m remove adjust restart, invoice columns from purchase model
* [33m3db7345[m edit a restart
* [33m2c0f7f4[m clean up post restart implementation; link restart amount to payment
* [33m049764b[m add tests for modifications
* [33mf6aa855[m architect relationship between parent purchase, child purchases and restart
* [33mdf68c5c[m implement restart model
* [33m3272af5[m hardcode freeze-charge for now; freeze index to descending order
* [33m084bce9[m add polymorphic payments to freezes; implement accepts_nested_attributes_for to Freeze model; implement stimulus on new freeze form so prompt for medical freeze policy followed
* [33m6e96764[m share stimulus controller shop-menu and public pages packages
* [33m08d8709[m stimulus to package policy (terms and conditions) toggle
* [33m7928346[m add temp new purchase message
* [33m95b065c[m add stimulus for client shop page
* [33m9681081[m handle purchases charting for superadmin
* [33m632743f[m hotfix wkclass repeats for unlimited product
* [33m9002617[m add adjust and restart index
* [33m4b9a199[m add toggle to commission/employee to admins instructors index
*   [33m92b87cf[m Merge branch 'hotfixfreeleance'
[33m|[m[34m\[m  
[33m|[m * [33m86b5eca[m add employee attribute to instructors and show instructor class without expense to superadmin
* [34m|[m [33m9d4c0a8[m add employee attribute to instructors and show instructor class without expense to superadmin
[34m|[m[34m/[m  
* [33me896501[m add index of freezes
* [33m1d2b402[m products table with filters
* [33mc75839a[m validate products
* [33m04f1bc1[m further div-ize of client dashboard tables
* [33me764962[m product#formal_name hotfix
* [33m796084e[m client history table div-ize
* [33ma32cd00[m make markers visible to clients
* [33m0940d33[m generalize product#name metho
* [33mbc22401[m pause product_combo_must_be_unique validation
* [33m56061e3[m update format of tables to div-style in product show
* [33m2c0e00b[m prohibit administrator creating a rider with unassociated main purchase
* [33m0b185ae[m hotfix marker forms
* [33mefcac89[m implement stimulus action to toggle hide/display of purchase form adjust and restart options
* [33me2e0995[m tidy up client acheivement tables
* [33m99890cf[m reformat client markers
* [33m7009f67[m order marker options/sort on created markers, not settings markers
* [33ma1162a4[m swith out in-file javascript to stimulus controllers (stage1)
* [33m30f75db[m automate A&R
* [33m64b58fc[m add bespoke filename to accountant excel data download
* [33m95ed9f2[m add filter by time to wkclasses index
* [33mcd21f5e[m add to purchase filters
* [33mdf736df[m partner workout_group show table hotfix
* [33m75fcb78[m hotwire strength markers
* [33m6a68fd5[m hotwire bodymarker form, (remove form validation error red borders)
* [33mae04d08[m add body markers, test markers, change strength marker weight datatype to float
* [33m1c9ea16[m improve shop page
* [33me54d1bd[m reformat Purchase#available_for_booking, correct and test remove from waiting list after booking different class
* [33m7181132[m hotfix client cant remove from waiting list having booked an alternate class on same day
* [33m6394da2[m implement client strength markers for admin
* [33m8af0317[m timetable deep copy implemented
* [33mca2cb47[m authorise junioradmin to sunset purchases. correct cancel button on new wkclass form
* [33me02a9ac[m reformat Wkclass.problematic
* [33m82c8570[m minor reformatting
* [33md9390e1[m rubocop auto-corrections implemented
* [33m769561b[m replace OpenStruct with Struct
* [33mc770af9[m rubocop app folder, stage2
* [33m3b3605d[m rubocop app folder, stage1
* [33m4d6dd08[m rubocop test folder
* [33mb9b65f9[m hotfix early cancel first booking
*   [33m1c3706a[m Merge branch 'hotfixnew_attendance_turbo'
[35m|[m[36m\[m  
[35m|[m * [33m23f7907[m qualifying purchases on wkclass show do not appear by default (as may take a few ms to load)
* [36m|[m [33m887f0cf[m qualifying purchases on wkclass show do not appear by default (as may take a few ms to load)
[36m|[m[36m/[m  
* [33m0ef0459[m color code attendances in attendance table for non-payment/close to expiry only once selected, not in the select box)
* [33m0f5d694[m detableize orders, client show, waiting list
* [33m88d5201[m detable-ize expenses, reg expenses, other services
* [33m49c56c8[m de-tableize discount index and expenses index
* [33m86ca759[m table to div tables for challenge, achievemnet, product, instructor, partner, workout
* [33m55b496a[m de-table-ize purchases; pass page as a parameter in wkclass links & forms (so returns to same page after an action)
* [33mfa50a4a[m remove residual instances of scroll: true from refernces to wkclass show path
* [33m8e64364[m wkclass attendance table to divs table
* [33ma15c121[m hotwire wkclass show
* [33m087939b[m reformat Whatsapp class
* [33m62b2368[m replace hardcode with settings in wkclass dropdowns
* [33m9f25b71[m testing settings with rake task
* [33mbfac6f9[m improve layout of workout group show
* [33m50e72b2[m reorganise purchases index columns. Test unexpired_rider_without_ongoing_main scope
* [33m9a9b8b8[m edge hotwire corrections (render correctly after cancel form after error on update)
* [33m02b2909[m check_if_already_had_trial a callback on the purchase method rather than a filter on the controller; improve hotwiring on form submission after errors
* [33m9410cc6[m add Purchase expired_in class method
* [33mdfde264[m show workouts by hotwire on workout_groups page
* [33mecc4e9b[m hotwire workout groups
* [33m0d34b39[m hilight active navbar item
* [33m4e0a581[m strip out early cancels from client PT page; improve dividers between packages
* [33meb8f3d5[m auto expire riders on expiry of main
* [33me3ee57b[m sensible limits to freeze start dates for client freeze form
* [33m6d07ccf[m auto cancel bookings made post expiry (due to eg penalty, freeze break)
* [33m4f5ef4f[m hotwire purchases
* [33m9497c4b[m hotwire purchase edit
* [33mb678271[m hotwire admin client page
* [33m7a370fc[m hotwire admin clients
* [33m59ca03c[m remove forbidden links from instructor
* [33m7b6c570[m hotfix flashes for instructor
* [33m7aaedea[m hotfix hotwire for admin adding errant freezes/editing freezes
* [33m1afad8e[m hotfix shop discount statement for oneoff discount
* [33m3152ac0[m show count of discounts
* [33md123c1c[m show all discounts if more than 1 applies on purchase/show
* [33m3b3148a[m add current to discount reasons
* [33m74ec3b4[m hotfix waitings destroyed when associated wkclass/purchase destroyed
* [33md196dd8[m add oj gem for speeding up pagy
* [33m2b43c71[m logged in superadmin  needs to include superadmin password in form to change password of other accounts
* [33m9ac6a77[m modify group class package expiry notification message
* [33mb5f4499[m hotfix link to client package form wkclass show
* [33m615b5c1[m make waiting list details visible to admin
* [33mf034599[m implement waiting list
* [33m737c350[m hotfix pagy_combo_nav_js
* [33md2a00fa[m hotfix ClientAnalyze, add Membership Class
* [33mdc80215[m add my bookings section to client book page
* [33m2366e95[m hotfix sunset, client cold, improve pagination styling
* [33mfef0cb9[m add client analysis download
* [33m0e7bd91[m hotfix cancellation of package modification forms
* [33m4b50bdc[m Implement client freeze own package, update freeze policy, stimulus for admin edit freeze start date
* [33maf8018d[m turboize admin freezes
* [33m29db12f[m hotfix error lingers from previous create wkclass error on wkclass form after successful create
* [33mb87d027[m change timetable
* [33mf34bc3b[m limit time interval on wkclass form datetime_select
* [33m22c4ff1[m make opengym slide by day; correct timing of session booking_day in attendances controller
* [33m26c530b[m add other services section to booking page
* [33m7b1d871[m add other services resource
* [33m84d6199[m add studio and duration to wkclass
* [33m2cbdb93[m add open gym to booking page
* [33m7c71ce1[m client count return/pagy component on clients index
* [33m8621cd0[m hotfix download data bug
* [33m6c176a0[m hotfix images not being greyed out when inactive
* [33m0d1c8b0[m hotwire wkclass form
* [33m0473ad4[m upgraded booking page
* [33mfcc6ed6[m add sliderised  wkclass booking table
* [33mfadc2d8[m hotfix turbo link to challenge on achievment index page
* [33m262ef4b[m css componentize, remove timetable_build.scss
* [33m7c2f468[m shift clients.scss content to components and remove clients.scss
* [33m739b84d[m complete componetisation of css classes in custom.scss and remove custom.scss
* [33m613628f[m css rearchitect, update buttons
* [33m34d252e[m continue componentising, reduce custom.scss
* [33m2e09fce[m add status (no show etc..) column to wkclass with instructor expense table on workoutgroup show page
* [33m07f8a28[m rearchitect css, remove admin.scss
* [33mbb6c0e7[m hotfix admin attendance update for turbo
* [33m351789d[m hotfix hotwire error on workout_group show and wkclass show
* [33me018471[m remove unused scss from cube template, in preparation for componentisation
* [33m0ed89fc[m hotfix signup failure
* [33m432de74[m hotfix dynamic update of freeze end date in new freeze form
* [33m179131a[m attendance hotwired
* [33m3d529ea[m hotfix update residual method: :delete in links for turbo
* [33mb8da309[m tooltip for when class is at  maxcapacity
* [33mdabca0a[m deletable? method for purchase and price models
* [33m46f692f[m improve bad password reset management with unprocessable entity status as render option
* [33m48dad94[m hotfix timetable swipe
*   [33m902cc94[m Merge branch 'slider'
[1;31m|[m[1;32m\[m  
[1;31m|[m *   [33m966be64[m Merge branch 'products'
[1;31m|[m [1;33m|[m[1;34m\[m  
* [1;33m|[m [1;34m\[m   [33m48aed48[m Merge branch 'products'
[1;33m|[m[1;34m\[m [1;33m\[m [1;34m\[m  
[1;33m|[m [1;34m|[m[1;33m/[m [1;34m/[m  
[1;33m|[m[1;33m/[m[1;34m|[m [1;34m/[m   
[1;33m|[m [1;34m|[m[1;34m/[m    
[1;33m|[m * [33m63967e5[m Rails 7 upgrade, Hotwired, ready to deploy
[1;33m|[m * [33m701d96e[m client pages hotwired
[1;33m|[m * [33m64d4341[m all admin and instructor navbar pages hotwired
[1;33m|[m * [33m6229f4a[m admin client, purchase and wkclass indexes all hotwired
[1;33m|[m * [33mb8a2eb0[m admin client page hotwired and autocomplete searched
[1;33m|[m * [33ma011b62[m replace incidences of Rails.fire
[1;33m|[m * [33m6289ec1[m client/purchase/wkclass filters responding with Turbo
[1;33m|[m * [33mc1f0bb7[m autocomplete for client search on new purchase form
[1;33m|[m * [33m1aca07a[m stimulus broadly working for discount change and date change on purchase form
[1;33m|[m * [33m96cd999[m stimulus working for wkclass form
[1;33m|[m * [33m836910e[m tests pass after upgrade, but AJAX in forms not working
[1;33m|[m * [33m9068774[m rails 7 upgrade (but UJS issue remains)
* [1;36m|[m [33m9e50a50[m hotfix accountant purchase data after pagy add
[1;36m|[m[1;36m/[m  
* [33mf76d802[m upgrade to ruby 3.2.2
* [33m840efc6[m replace kaminari with pagy
* [33m2179f19[m housekeeping
* [33mf86eaf0[m routes tidy
* [33mcaed764[m improve button/icon hovering
* [33mbcb9f18[m reformat accounts_controller #set_account_holder
* [33m676e435[m add header to request in test to test redirect to referrer; other minor housekeeping
* [33m416c434[m add erd gem, error recue when attempt to login to account with no client
* [33mfbcc951[m add has_role scope to account model and extend accounts index to instructors
* [33mc9c6aee[m rescue error when admin attempts to show a wkclass with invalid id
* [33m1fc36a4[m hotfix sunday timetable bug
* [33m4d744fa[m hotfix swipe up is mistaken for swipe across
* [33m388857c[m replaced tiny-slider dependency with bespoke js; added day name to timetable slider buttons
*   [33m4fd4369[m Merge branch 'tooltipexp'
[31m|[m[32m\[m  
[31m|[m * [33mb14c813[m remove some more residual cube js and scss
* [32m|[m [33mcde1e11[m remove some more residual cube js and scss
[32m|[m[32m/[m  
* [33mc7cd8ea[m remove unused javascript dependencies
* [33m267d372[m remove aos and isotope dependencies
* [33m34536e1[m replace headroom dependency with bespoke javascript
* [33m2bd112e[m align timetable items on bigger screens
* [33mb741132[m last_counted_class method add account/password reset available to admin through client show some simple hygeine remove errant JS from achievement_chart page
* [33m32062b2[m add AccountCreator class and password wizard concern
* [33m4287bac[m finalize group class page
* [33m189d5a9[m improve and test daily account limit
* [33m64cd051[m admin can add client attendance directly from wkclass page
* [33m7e4ce08[m add descriptions to signature classes carousel
* [33m394eeb7[m add hearts
*   [33mef2d4d0[m Merge branch 'hotfixtt'
[33m|[m[34m\[m  
[33m|[m * [33m226a7c4[m add testimonials/change timetable constant
* [34m|[m [33m6b1f751[m add testimonials
[34m|[m[34m/[m  
* [33m727e6b1[m development of group classes page
* [33m1b90466[m wkclassmaker refer to workout mas capacity attribute
* [33ma84e267[m improve wkclass #problematic so late package no shows with penalties dont trigger
* [33m4577f22[m testing for booking opn gym and client booking interface when class is full
* [33m22bf699[m shop page, default to unlimited or fixed based on last product
* [33m5a55b50[m remove hardcode of trial price from razorpay button text
* [33mecbe8d0[m add default_capacity to wkclass and implement into data attribute on wkclass form
* [33md7b3b91[m fix and reformat instructor rate dropdown population in wkclass form
*   [33m0c2b809[m Merge branch 'groupclasspage'
[35m|[m[36m\[m  
[35m|[m * [33m2973c40[m first stage group class page
[35m|[m * [33mcbf36af[m time for renewal filter for purchases
* [36m|[m [33mc76502e[m time for renewal filter for purchases
[36m|[m[36m/[m  
* [33m6c62c1a[m fix display of score for main challenge from client dashboard
* [33m123623a[m improve full class ux
* [33m57498ab[m Make a clean exit on Heroku while running a rails console
* [33m64253a5[m Upgrading to heroku-22
* [33m371708e[m add limited to workouts and allow workouts that are not limited to be booked same day as another
* [33m8c0f880[m reformat challenge results data
* [33m6174b39[m add instructor commission attribute and direct to appropriate page on login
* [33mb04fd5d[m set timetable as constant
* [33mb997769[m instructor can view classes and take attendance
* [33md71fc15[m reformat challenge results
* [33m09e2252[m rubocop
* [33m5e2736d[m fix bug where inappropriate client intended flash shown to admin on new purchase
* [33mc9fbaee[m allow for main challenge not having directly associated achievements
* [33m167cca5[m hofix challenge edit fail and validate challenge name length
* [33m2de6c76[m hotfix select on profile page chart incorrectly  sends to achievements page
* [33m1d8663b[m implement sub-challenges
* [33mcb11010[m client challenge league on dashboard
* [33m7d1578e[m improve charting on client dashboard
* [33m289f01d[m refine PT policy
* [33me50f571[m chart client progress
* [33m17c695f[m challenge prototype
* [33madc7549[m hotfix duplicate color in product show view
* [33mb2765ef[m add discount details to client dashboard
* [33m8c38cd1[m access to homepage when logged in
* [33m44f198d[m hotfix ruby update error
* [33mbd3a565[m upgrade ruby to 3.1.2
* [33m64326be[m Returning to heroku-20
* [33m26eddb8[m Upgrading to heroku-22
* [33mb463f4c[m enhance purchase methods for expiry of rider benefits eg #expired_on
* [33m70dcc4b[m add pt policy
* [33m2468cce[m fix to unexpired_rider_without_ongoing_main
* [33m577eada[m add warning to oneoff discount index
* [33m4fcfdd6[m add status of attendance to instructors payment schedule when PT on instructor show
* [33mcbcf73d[m hotfix new wkclass form when instructor/instructor-rate not set
* [33m4316b11[m add parameter and setting to wkclass #past to impact #problematic to remove legacy cases from search
* [33m803a15b[m create account for pt clients on purchase
* [33m496dfc9[m dont show rider benefit in booking window until PT started; update rider expiry in sync with PT package
* [33m78b900d[m for pblic/client timetables entries hash in controller, avoid database query in view
* [33m1145051[m correct missing formatting on signup/new client form for virtual attrributes eg whatsapp_raw
* [33m2fbcaaa[m add reviews to homepage
* [33mbcf37d0[m add booking post purchase expiry to wkclass #problematic
* [33md1e609b[m validation so ok to duplicate PT class where client has early cancelled for rescheduling with another client
* [33m2b4bf9c[m correct whatsapp for new purchase
* [33m4ca872b[m correct sessions issues around roles
* [33mda47132[m new homepage, new footer logo
* [33m7edca00[m workaround for issue with phones deleting sessions
* [33m36bbce4[m lots of Rubocop
* [33m5c97ddc[m tidy up homepage and signup form
* [33m237e26b[m clean client history page, rubocop
* [33mfaf6648[m change provisionally expired to classes all booked
* [33m3dedf1a[m implement forgot password. Move deal with post login functionality to application controller so can be accessed after password update as well as normal login
* [33mdddf9d3[m tidy up & expose client PT page
* [33mdf2af97[m implement password reset
* [33m3a2c79c[m add pt repeater to wkclass show/controller
* [33m7b73805[m product #formal_name with color
* [33mefa6904[m correct heading in client book when rider expires; only group packages in package list in client book
* [33m6334c42[m hotfix residual reference to price.name in expiry revenue; add icons to wg index
* [33m584145f[m auto ptrider by self join on purchases add workout_group service and requires_account fields client pt page development Purchase service_type scope delegation of pt?/groupex? methods from purchase through to workout_group
* [33m7b595ea[m hotfix admin client show fail because of old price helper method dependent on deleted price columns
* [33md4bea57[m remove columns from prices table not needed after rearchitecture
* [33m5dad9d8[m add write off filter to purchases
* [33m9d33115[m functionality for no instructor workout for wkclassmaker
* [33m38b8123[m unpaid in red in new attendance dropdown
* [33mb28c6a5[m remove reference to missing partial layouts/_home_navbar, which affected clients with expired sessions clicking on timetable
* [33m2a60fcf[m order discount discount_reasons default razor-pay orders to captured fix inaccessible items on dropdown on phone
* [33ma95d66d[m discount tables by current, not current
* [33mae8929e[m remove redundant table columns from views post purchase discount re-architecture
* [33m8ee9209[m hotfix discount purchase update; no round to 50 when discount is price change transition
* [33m168f474[m correct accountant data
* [33mae12537[m product colors to settings, discount names ordering, product & discount ids temporaily in index tables
* [33m6ee503f[m allow junioradmin to delete empty classes
* [33m2bd8414[m hotfix rounding to 50 with no disocunt on new purchase form
* [33mb061af4[m hotfix new price form
* [33m7286f9c[m add color to product
* [33m5ff780d[m add commercial and discretionary discounts to new purchase form
* [33me99d05a[m shift discount names from constants to settings
* [33maeb8681[m rearchitect discount model
* [33ma2c0161[m add part of whatsapp group indicator to clients
* [33m9952597[m razorpay orders index
* [33md0c6b3c[m reformat orders and fix issue where logout happens before shop purchase completes
* [33me04d80b[m test double signup fails and add mail blast
* [33m95de99c[m add A&R details to accountant download
* [33ma41aa49[m test correct account/assignment creation on new purchase
* [33m44c3e91[m add superadmin tests to password reset tests
* [33m8a5391c[m hotfix create assignment when new purchase triggers new account
* [33m200d664[m eliminate N+1 queries with Bullet
* [33m5ec324e[m add honeybadger error reporting
* [33mf4a3ab6[m add account roles
* [33mcbc230b[m callback and validation on workout name
* [33m7886cbe[m add client_ui indicator to Order model
* [33mb22a546[m hotfix whatsapp messaging number concern for instructors
* [33m41a9446[m implement new account message for instructors
* [33m2e35548[m replace wkclass incomplete/instructorless/empy with charge filters with problematic filter
* [33me9f39cc[m hotfix instructor expense filter not working for partrners
* [33mca9440e[m change account has many partners to account has one partner
* [33mef0a504[m change account has many clients to account has one client
* [33m5d98e26[m tidy up navigation bars
* [33m75d7955[m implement option to add classes over multiple weeks
* [33m6bc1356[m donload purchase data for accountant
* [33m44eb171[m hotfix undefined method for nilclass on instructor/workoutgroup show when class attendance is zero
* [33m8226b33[m retire products by button click and improve sorting
* [33mb898e31[m instructor account show sort
* [33me87a19a[m introduce instructor accounts
* [33me978a59[m add attributes to instructors, prepping for accounts
* [33m3e0c073[m hotfix instructor rates not appearing in new wkclass form for junior admin
* [33mf98c241[m fix edit class iro instructor rates available
* [33m9427924[m format instructor_rate name for new class selection
* [33md6cc127[m retire instructors by button click
* [33ma4957b0[m retire instructor rates by click and order nicely on index
* [33mec3460a[m retire workouts through button click
*   [33m8f5b251[m Merge branch 'instructors'
[1;31m|[m[1;32m\[m  
[1;31m|[m * [33m27628cd[m rearchitect instructor rates
* [1;32m|[m [33m26d163e[m hotfix client phone in index wont show when whatsapp only
[1;32m|[m[1;32m/[m  
* [33mcf6ab0c[m add edit link to wkclass show
* [33m6ec5fec[m superadmin can update passwords throuh UI
* [33mcdf0ea5[m client number search
* [33mde315b3[m correct product sorting
* [33mc9c9048[m only show current in workouts filter
* [33mb445554[m show classes attended for packages on client page. Set only currrent instructors (and ordered) in workout group show filter
* [33m195740a[m filter workout_group instructor expense by instructor
* [33m96e0ea0[m abstracted some hardcoded items to settings
* [33mad9e0e5[m shift constants to UI changeable settings
* [33mb8c756f[m prettify Settings page
* [33m3d0ce23[m fix bug on new timetable page
* [33ma5b04c7[m add instagram feed to home
* [33m8f28186[m fix saving is zero on shop page
* [33m57d13d5[m homepage improve
* [33mf93f8bf[m fix razor form hidden inputs and test
* [33mbbc503a[m international prefix added for new client form and associated client methods
* [33mee70b5f[m add waiver to signup form and signup tests
* [33madfa9aa[m cosmetics & t&cs tidy
* [33m21443ea[m accordion text to homepage
* [33m7681560[m add instructorless and incomplete filter to wkclasses
* [33m70eb60f[m fix bug on signup form when invalid phone/whatsapp
* [33m630ddb6[m add whatsapp message re password reset improve client update from admin POV (insta/waiver update link from client page)
* [33m10cc7be[m Add Renewal Class Improve shop design
* [33m5735431[m filter purchases by sunset
* [33me05967a[m add admin capacity to expire purchases after sunset date
* [33m6b03201[m add sunset date
* [33me27784c[m add client password change feature
* [33md5347d2[m add sort to products page
* [33ma8c2adb[m make montly purchase amounts visible to admin prevent a client purchasing more than 1 trial fix bug with new purchase (client search returns nil) fix bug where online purchases is sent a message
* [33m17d1329[m fix sort purchases by expiry date & filter by package not trial
* [33mab0ea1d[m correct fast double click ccould cause double booking with already_booked_for? method
* [33m0e51e3d[m client dropdown select for new purchase
* [33m9efd704[m strip whitespace from client names
* [33mc745e87[m with options to phony normalize
* [33m1a4636f[m mailchimp code
* [33m262655f[m switch to client#modifier_is_client & format client numbers
* [33m2284308[m hotfix associate_account_holder failure
*   [33ma649412[m Merge branch 'phony'
[1;33m|[m[1;34m\[m  
[1;33m|[m * [33m9ca48d2[m add phony gem and validate client whatsapp/phone
* [1;34m|[m   [33mcb1f7ed[m Merge branch 'clientbook'
[1;34m|[m[1;36m\[m [1;34m\[m  
[1;34m|[m [1;36m|[m[1;34m/[m  
[1;34m|[m[1;34m/[m[1;36m|[m   
[1;34m|[m * [33m4fda0ef[m correction for expired package, alert_to_renew? method
[1;34m|[m * [33m7848496[m correct display of discount for trial
[1;34m|[m * [33mc6eb10c[m test suite for shop
[1;34m|[m * [33mc007497[m client book page reorder, broaden wording and test
* [1;36m|[m [33m8987d47[m add #just_brought_groupex? to fix accidental account set up for eg online training client
[1;36m|[m[1;36m/[m  
* [33m9bca398[m test renewal stage 1
* [33md29ec8c[m improve manage_messaging method and some I18n abstraction
* [33mfed1f5d[m hotfix to avoid crash when purchase somehow created with no price
* [33m2594da8[m post signup notification.  add has_purchased method so trials are only available to new clients.
* [33mb862264[m go to shop after signup
* [33m04613a7[m add country gem for signup form
* [33m676cc7a[m improve signup form & favicons
* [33md177fa2[m fix bug on signup form failure. Add account daily limit
* [33m29a8047[m improve shopping table
* [33mab2517c[m add sellonline to products
* [33me2cdf69[m shop order products by days with aos
* [33m3d3480f[m tidy up layout of client pages
* [33m25f6ddf[m tidy up admin pages layout
*   [33m0211957[m Merge branch 'dynoshop'
[31m|[m[32m\[m  
[31m|[m * [33m21c60f4[m razorpay from public shop or logged in renewal, dynamic shopping options
* [32m|[m [33m3be4ff7[m fix new account message failing because first name not supplied & junioradmin can password reset
[32m|[m[32m/[m  
* [33ma136c98[m razorpay for shop, thank you page, product base price
* [33m77966b3[m provide range of months to add regular expenses to
* [33mdc37334[m update social media icons
* [33m88a25ce[m shop page
* [33mdbce96a[m allow junioradmin to rest password
* [33mfcb5344[m enhance junioradmin access to clients
* [33m864ea46[m homepage redevelop stage1
* [33ma776049[m allow admin to delete wkclass with nil attendance through UI
* [33m2dbfea3[m allow admin to delete accidental purchase/client through UI
* [33me9e85d5[m timetable options to settings
* [33me42133c[m add regular expenses
* [33md0f9e2f[m eager load workoutgroup show
* [33m452a6ca[m show instructor cost sum and count in workoutgroup summary
* [33m6664195[m updates and improvments to whatsapp messages
* [33mb0fe3aa[m opengraph to other pages
* [33m2158532[m rake task to update trial renewal prices
* [33m4c88eee[m add settings for package renewal discount
* [33mc2009c6[m add policies to footer
* [33m848e6ce[m add terms and conditions
* [33m1e1def9[m setting for wkclass maker days ahead
* [33m1c97919[m add favicon
* [33me4a0e1e[m fix trubo and og and some W3C validation
* [33m8f4054c[m improve open graph
* [33m24e28db[m Open Graph Protocol
* [33mb5d5d43[m temporary live homepage
* [33m8277f38[m timetable setting
* [33mcf5588f[m automate create wkclass from timetable
* [33m2f08129[m add level to wkclass
* [33m77beb2f[m associate timetable entries with workout
*   [33mc83739c[m Merge branch 'datanoturbolink'
[33m|[m[34m\[m  
[33m|[m * [33m05d8e1e[m slider timetable for client and public
* [34m|[m   [33m3d1088b[m Merge branch 'datanoturbolink'
[35m|[m[36m\[m [34m\[m  
[35m|[m * [34m|[m [33mae44462[m data-no-turbolink on links to pages with tinyslider
* [36m|[m [34m|[m [33m7ebfb14[m remove turbolinks
[36m|[m[36m/[m [34m/[m  
* [34m/[m [33ma890405[m slider timetable for client and public
[34m|[m[34m/[m  
* [33m7862dfd[m fix bug where 2nd booking on same day under a different purchase is restricted. Only show classes in Space workout group in client bookings table
* [33m7ba5849[m sign up and buy
* [33m12ef78d[m restore flash for login fail
* [33m806edda[m improve slider controls
* [33mcf57cab[m fix asset path of background image and entries time order
* [33m91380c5[m slider timetable
* [33mdc32dfd[m implement tinyslider on homepage
* [33mf369521[m timetable to navbar public
* [33ma5e5ef2[m correct line-height in navbar/wkclass show
* [33m70f020e[m add methods for bulk freezing
* [33m7300271[m line height (dropdown & label format)
* [33mce794fc[m add instructor initials to workout name in wkclass table
* [33m2a433ba[m retire instructor rates change links to text for junioradmin where the link would redirect to login (eg client name in clients index)
* [33m556e211[m retire instructors
* [33m7155794[m retire old workouts
* [33m824be23[m new client navbar
* [33m6a2bcaf[m correct client styling
*   [33m58d8d58[m Merge branch 'clientpage'
[1;31m|[m[1;32m\[m  
[1;31m|[m * [33mc317fae[m make public stylesheet redundant
* [1;32m|[m [33mcfff757[m make public stylesheet redundant
[1;32m|[m[1;32m/[m  
* [33m91a6f93[m timetable time of day and lots of minor styling
* [33m0554ab3[m start to spaceize the theme
* [33m4b09b9c[m theme working with scss outside packs
* [33m5d3ceb5[m scss outside pack working
* [33m6f11178[m re-implement timetable manually from tempwelcome
* [33m9b340fb[m client one time trial filter
* [33m18a57b2[m tidy routes
* [33m2ee8bcf[m reformat login and broaden login tests
* [33m12a08ab[m layouts
* [33m5c88fd8[m minor view correction
* [33mb1798f2[m renew online
* [33m49d3d25[m any step change to price discount
* [33mbd312c0[m amnesty limits avaliable through settings
* [33m572cdb4[m fix error on invalid add/update of product
* [33m2e93196[m timetable builder
* [33mc4c1db4[m git error
* [33mc06608b[m we donotsupport
* [33ma3dfed9[m pricing page
* [33mc0f7c1f[m full name price helper fix
* [33m8dc7451[m rupees helper
* [33m3724358[m price formal name helper
* [33macd99c6[m change discount to float
* [33m15e2ee4[m settings error hotfix
* [33m01375ef[m amnesties can be changed through user interface
* [33m7be9b94[m fix superadmin add product & step 0.1 on Price discount
* [33m2d2187a[m rupee paisa order fix
* [33md9aaee6[m per page increase for handle_export methods
* [33ma3cc80a[m nav bar extend and paise for razor
* [33m1e0c3ca[m add Instagram waiver
* [33mfcc7903[m fix so account email updated when client email edited
* [33m9fcceec[m hotfix renewal_price
* [33md05338e[m space group only discount prices fix
* [33mbdf30cd[m Redesign of Prices
* [33mc7880cc[m new purchase form - only select current prices
* [33m81a79e5[m trial expiry messaging
* [33m9f9463b[m package expiry message
* [33me56ba26[m no whatsapp or inappropriate flash when client late cancels themself
* [33mb66fc83[m correct renewal trials
* [33m33be35f[m remove razor seed file
* [33mc3e9364[m remove git merge headers from schema after merge conflict
*   [33m9803258[m razor renewal
[1;33m|[m[1;34m\[m  
[1;33m|[m * [33m91ebd1a[m razor renewal
[1;33m|[m * [33meadba14[m razor renewal
[1;33m|[m * [33meebd9c5[m first razor cut
[1;33m|[m * [33m3ec8e60[m razor test
* [1;34m|[m [33mee82c0f[m footfall
* [1;34m|[m [33m278fe30[m booking window extended
* [1;34m|[m [33m22cc3ea[m blank method reformat
* [1;34m|[m [33m36e88f3[m fix Client.active.packagee filter
* [1;34m|[m [33mba2be0c[m fix timezone hack
* [1;34m|[m [33m74f1e9b[m hack for timezone for groupdata
* [1;34m|[m [33m54a253c[m set timezone for groupdate
* [1;34m|[m [33m1d283e8[m purchase charting
* [1;34m|[m [33m7b59142[m fix close_to_expiry hack & PT EC
* [1;34m|[m [33m0b4a375[m client waiver
* [1;34m|[m [33m17c5df8[m active client
* [1;34m|[m [33m83a84d9[m T&Cs & name in new purchase message
* [1;34m|[m [33mfdff129[m reformat forms with collection_select
[1;34m|[m[1;34m/[m  
* [33ma440410[m client show improve
* [33mf1532ce[m fix pt noshow amnesty
* [33mee35f26[m automate fitternity purchase on booking
* [33m25e5bc6[m correct PT wkclass validation
* [33m9222d80[m remove whitelist
* [33m14c900a[m message blast, client pt
* [33m4a6ddbc[m PT class/instructor validation
* [33m754b35d[m instructor expense subtotals
* [33m79d398f[m correct LC by client messaging
* [33m9eb3d24[m separate PT/Group amnesty_limit
* [33m4715733[m export data
* [33md642247[m rebook ok sameday after LC/noshow
* [33m7bbbeb5[m validate Fitternity payment method
* [33mc2afde6[m external JS file & razorpay
* [33m67ec73a[m correction to form when Fitternity
* [33m2a48a8f[m fitternity payment method default when fitternity price
* [33me5773ce[m correct whitelist
* [33m1a943e3[m settings
* [33me87922e[m expires_before? method, whitelist clients
*   [33m2e320d7[m Merge branch 'noshowtolc'
[1;35m|[m[1;36m\[m  
[1;35m|[m * [33me2e2787[m toggle attendance status & service object
* [1;36m|[m [33m5924576[m booking window closed
[1;36m|[m[1;36m/[m  
* [33m8169a8b[m reformat wkclass has many methods
* [33m0d86df7[m booking table w window headings
* [33mf9c698f[m fix freezes method
* [33mcba9562[m password reset
* [33m370e4a0[m password reset
* [33md9e2a38[m whatsapp concern & account create
* [33m24508de[m purchases dop sort with AR lower priority
* [33m681ce41[m AR date not null after purchase update correction
* [33m44935e1[m rubocopping & readme
* [33m8334ae0[m rubocop minitest
* [33m2083eaa[m validate freeze can't overlap attendance
* [33m56684be[m freeze end on booking confirmation
* [33me21d9f6[m messaging late cancellation
* [33m9abdd50[m subquery has too may columns hotfix
* [33m6e3c175[m efficient sum of purchase payments
*   [33m47cd5ee[m Merge branch 'noshowmessage'
[31m|[m[32m\[m  
[31m|[m * [33mc0dd3dc[m whatsapp no show penalty
* [32m|[m [33m42b3602[m speed up after inefficient payment summation
[32m|[m[32m/[m  
* [33m9a7f4e7[m minor correction
* [33m29e811f[m correct purchase revenue summary
* [33m01239f4[m monthly purchase revenue summary
* [33m74b56aa[m csrf error force_ssl; included frozen exclude post dop from qualifying purchases
* [33m3d5d523[m wkclass attendance order in table
* [33m6f50021[m update table for wkclass attendance
* [33m3f49f98[m attendance during freeze
* [33mfddb303[m add back payment mode
* [33mbe9e4ba[m make packagee filter exclude expireds
* [33m2691f90[m remove doubled-up class wkindex
* [33mca7b0a5[m remove destructive options from UI
* [33mc69eadf[m fix client sort
* [33ma1acd42[m client sort
* [33m2c1c5b1[m correct disaply of fixed expense total
* [33m70e4192[m date filter on expenses
* [33meaee185[m improve presentation of tables part1
* [33mcf94c93[m improve UI for purchases show
* [33m58f6538[m booking interface test
* [33mad72f14[m improve formal_name method
* [33m4e1c746[m flash helper for multi-message, multi-line
* [33m8f4d08e[m correct whitelisting
* [33me74e1ad[m format messaging numbers
* [33m170327f[m twilio whitleist & PT method
* [33m45701e4[m correct handle_update_booking method
* [33m9a808f5[m reformat client helper
* [33mdb021fb[m consistency methods
* [33m50fc088[m client profile
* [33mf988a42[m improve client UI
* [33mb189285[m correct client history
* [33md232c17[m navigation bars
* [33m9dc3746[m fix attendance_status so fitternity purchases that are booked are recognised as provisionally expired rather than not started
* [33m274f113[m add trial & fixed sort attributes
* [33m2c10a37[m more reformat of attendances controller
* [33m8c15994[m attendances controller reformat
* [33maa13167[m split attendances amnesty/no-amnesty in purchase show
* [33m7bf31e2[m reformat revenues
* [33m394efa6[m purchases filter and sort reformat
* [33md159f65[m reformat and expiry revenue correction
* [33ma29a953[m client controller reformat
* [33m2409b50[m fitternity dummy package
* [33m281b9b8[m full reformat purchase model
* [33m5c2dc57[m stash first stage reformat purchase status hash
* [33m7645851[m abstracting text and reformat
* [33mbaa80e1[m I18n start & remove script preventing JS
* [33m5652435[m client navbar
* [33m3639d7c[m pause penalties & amnesties in production
* [33m5f4a557[m more rubocop
* [33m29f37d7[m reformat and rubocop
* [33md58506c[m some minor fixes & further booking tests
*   [33m6ed1d48[m Merge branch 'reformatconfigs'
[33m|[m[34m\[m  
[33m|[m * [33mb992d2f[m improved tests, flashes, early cancel record
* [34m|[m [33mbe522df[m improved tests
[34m|[m[34m/[m  
* [33m6cb21fd[m amnesty by product type
* [33m235db8a[m promote junioradmin
* [33m9600b77[m refactor booking flash
* [33mb791970[m show and test penalty
* [33m5e87817[m correct timezone
* [33m3fdfee4[m correct allow for attended status
* [33mfa8f8e1[m remove byebug
* [33mec4d30d[m add penalties
* [33mf217c8e[m new wkclass form with dynamic update of max capacity
* [33mfa4d622[m add max_capacity
* [33m24e3658[m turn off messaging
*   [33m1a81263[m Merge branch 'booking'
[35m|[m[36m\[m  
[35m|[m * [33mcf32ed3[m well developed booking system
[35m|[m * [33m5823944[m first try at booking system
[35m|[m * [33md92f8b5[m booking progress
* [36m|[m [33m9048fe4[m Fitternity correction
[36m|[m[36m/[m  
* [33mce8d5ac[m Fitternity recorrection
* [33mf321621[m correction
*   [33mddd3dd0[m Merge branch 'passwordgen'
[1;31m|[m[1;32m\[m  
[1;31m|[m * [33m22eb658[m notify purchases to the boss
[1;31m|[m * [33m8813fb4[m password gen
[1;31m|[m * [33m7810c35[m password generate
* [1;32m|[m [33mb61555b[m add skeleton
* [1;32m|[m [33m3ea6862[m client page
[1;32m|[m[1;32m/[m  
* [33m4de7d7b[m whatsapp class
*   [33m092312d[m Merge branch 'automaterakicheck'
[1;33m|[m[1;34m\[m  
[1;33m|[m * [33m1f47dfa[m whatsapp class
[1;33m|[m * [33m555e169[m first stage twilio template
[1;33m|[m * [33m49726ed[m first stage delayed job
* [1;34m|[m [33mf2ddb7e[m hotfix set fitternity_id
* [1;34m|[m [33m7da7f78[m correct instructor cost in wkclass_params and order instructor rates
[1;34m|[m[1;34m/[m  
* [33m2c3a3d8[m more purchases refactor
* [33m680efd4[m refactor purchases controller 2
* [33m669eec0[m refactor purchases controller
* [33mb39bb81[m twilio setup
* [33mb3a303c[m rake task for updating purchase status
* [33mf52ce03[m scheduler test
* [33m02e1bbf[m reformat & 1 class per day
* [33m8f0f646[m update purchases ymls and tests following migrate
* [33mada4e26[m refactor purchase status
* [33mf174701[m testing with better test data
* [33mf41e516[m rake taskfor fixtures added
* [33m91b71eb[m ignore fixtures
* [33m4c087f2[m validate wkclass unique time workout instructor
* [33m8db419a[m purchase model methods reformat and test
* [33me9a15f5[m correct attendance update JS
* [33m3ac478c[m start purchase model methods tests
* [33mf3a2d18[m controllers tests, prices validation
* [33mfe303e6[m controller tests1
* [33m726c61a[m add rubocop
* [33m83c4084[m testing models2
* [33m13dc9a4[m model testing1
* [33m0659ffe[m correct wkclass scroll error when not accessing through the main wkclass index
* [33mf2c8103[m prevent edit of class name after attendance already added
* [33mf462047[m export client data
* [33mc0e38e1[m hot & cold clients
* [33m128a9ba[m hot & cold clients
* [33m0a35e04[m add index to price_id
* [33m51eda42[m alt price_id migration
* [33m3cf71f4[m remove byebug
* [33mec09d03[m add purchase.price
* [33m1c92d09[m remove byebug
* [33m28c3ee6[m class filter by today
* [33m9d4394f[m correct link of wkclass from client attendance table iro class_period inconsistency)
* [33m0e74a5c[m links on client show attendances
* [33m9d21653[m mobile friendly
* [33m3fcf2b8[m filter clients by enquiry
* [33mde6192b[m add indexes to models to improve speed
* [33m5f67827[m efficiency1 add index to client names
* [33m4af888c[m workout group tidy
* [33m5c8837f[m wkclass index improve
* [33m8936a2d[m remove byebug
* [33m4c7b4c3[m filter class by workout group
* [33m9224417[m dropin method
* [33m1be3301[m format qualifying purchases close to expiry
* [33m67886bb[m a few minor changes
* [33m35d1117[m improve purchase index and form
* [33m4294643[m hotfix
* [33mc84e2fc[m add purchase details on client show
* [33m1076d57[m classpass filter
* [33md35e1b6[m improve fitternity show
* [33mffe87d0[m byebug residue remove
* [33m3d52084[m correct prev next class
* [33m6349ad4[m improve speed of attendance new
* [33m5c7354c[m test alt qual purchase method
* [33m72d8169[m correct qual purchases order
* [33m2fbb053[m qualifying purchase reformat
* [33mdeb9a2c[m order fitternity
* [33m5895e50[m speed up wkclass index
* [33m07ce8ad[m correction
* [33m3b254ca[m speed up clients index
* [33mba57aa8[m paginate clients
* [33me1caa64[m partners improve
* [33m353d156[m links on client show
* [33mf5a6f84[m scroll through classes
* [33md482cb9[m byebug remove
*   [33m562e467[m Merge branch 'master' of github.com:SimBed/attendnace_system
[1;35m|[m[1;36m\[m  
[1;35m|[m * [33me32ba8d[m junioradmin, logged_in_as method
* [1;36m|[m [33mc1c935c[m correct
* [1;36m|[m [33m4a675dc[m junioradmin, logged_in_as method
[1;36m|[m[1;36m/[m  
* [33m0ffab96[m minor correction
* [33mf541bd9[m invoice icons for workout group
* [33m5a0d001[m improve purchases & invoiceable workout_groups
* [33m28431a0[m whatsapp correction
* [33m0062877[m improvement to client show
* [33m6e04e6b[m provisional expiry status error fix
* [33m5d31479[m improve client show part 1
* [33m131cfe0[m client table reformat
*   [33mb843052[m Merge branch 'booking'
[31m|[m[32m\[m  
[31m|[m * [33m172b8e4[m add booking functionality
[31m|[m * [33me3e8912[m first stage of booking
* [32m|[m [33md894956[m quickfix for instructor expense
[32m|[m[32m/[m  
* [33mdb493a3[m partner tests
* [33m327cbc3[m unpaid filter
* [33m9d2a854[m correction
* [33m5f665af[m filter by close to expiry and invoice
*   [33mea55f92[m Merge branch 'testing'
[33m|[m[34m\[m  
[33m|[m * [33m6abe3be[m first tests
[33m|[m * [33ma1f9a64[m client model testing
* [34m|[m [33m0863b6d[m correct error in correct_account method
[34m|[m[34m/[m  
* [33m05409a6[m remove byebug reference
* [33medef031[m partner access
*   [33m02e201f[m Merge branch 'clientshow'
[35m|[m[36m\[m  
[35m|[m * [33mf871531[m account client relationship
* [36m|[m [33m86d4433[m gst indicator
* [36m|[m [33mcd5f326[m instructorcost
* [36m|[m [33mbf7bd87[m corrections
* [36m|[m [33mf081987[m instructor rates tidy
* [36m|[m [33m38e8196[m correction
* [36m|[m   [33m057104c[m Merge branch 'partnerrevenue'
[1;31m|[m[1;32m\[m [36m\[m  
[1;31m|[m * [36m|[m [33mea30954[m partner revenue superadmin
[1;31m|[m * [36m|[m [33mc7aa38e[m expenses
[1;31m|[m * [36m|[m [33mb3f7ab6[m partners
[1;31m|[m * [36m|[m [33me650906[m instructor rates
[1;31m|[m [36m|[m[36m/[m  
* [36m/[m [33mbfb8099[m correct expiry for products with days
[36m|[m[36m/[m  
* [33m487542e[m correction
* [33m2ffa4fd[m link correction
* [33m8221b26[m stage1 client login
* [33m1c2c5c8[m implement admin namespace
* [33me904e74[m stage 1 login
*   [33m004e015[m Merge branch 'kaminari'
[1;33m|[m[1;34m\[m  
[1;33m|[m * [33me0c1371[m add Kaminari
[1;33m|[m * [33m19cc8ca[m add kiminari
[1;33m|[m * [33m4b0bcfd[m add instagram to clients
* [1;34m|[m [33mbbacb7e[m add instagram to clients
[1;34m|[m[1;34m/[m  
* [33m7e458c2[m remove require byebug
* [33m51dc520[m search purchases
* [33m7231fca[m validations & minor improvements
* [33m0b4d50e[m remove byebug refs
*   [33m31ef557[m Merge branch 'price'
[1;35m|[m[1;36m\[m  
[1;35m|[m * [33m302891d[m add price model and full name for products
[1;35m|[m * [33mdc24c44[m price in progress
[1;35m|[m * [33m7824e28[m jquery rails fire dropdown ajax
[1;35m|[m * [33m0fc392e[m ajax working
[1;35m|[m * [33m8fa831f[m price history to product index
[1;35m|[m * [33m1f894af[m stage 1 of prices
* [1;36m|[m [33m119ac38[m correct freeze
[1;36m|[m[1;36m/[m  
* [33m4b58e18[m fitternity validate
* [33ma32d7e3[m correction
* [33m8e2e87c[m fitternity
* [33m54b06dd[m add all to classes select
* [33m2798e77[m show expiry
* [33m749b885[m correct expiry date
* [33m22f0b92[m status hash
* [33m3635a47[m correction
* [33m8432dd8[m correct attendances remain
* [33mc992075[m 2 part navbar
* [33m30cab97[m styling
* [33m5449fa2[m style purchases
* [33m1623462[m remove byebug require
* [33md480273[m purchase filtering
* [33m6d74a7d[m fiddle with bootstrap
* [33m500b391[m correction
* [33m895d647[m multiple improvements
* [33md02b6b8[m attendance by group
* [33m8d7cf2a[m reformat table data
* [33m9b2c2d0[m seed data
* [33m014b50a[m correction
* [33m9e781dd[m add freeze & adjustment
* [33mc993557[m purchase expiry at database level
* [33m1e16b57[m expired package revenue
* [33m4ada730[m rename models
* [33m35a03f5[m revenue
* [33m015bdd1[m rearchitect with workout group
* [33m4aa62eb[m select dropdowns
* [33m6344143[m architecture and seed data
* [33ma4456d7[m early prototype
* [33m1ee0e1a[m initialise repositiory
