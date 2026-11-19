# BTCL Complaint Management System

## এই সংস্করণে যা আছে
- Admin login
- গ্রাহক তৈরি/সম্পাদনা এবং ID, নাম, ফোন দিয়ে অনুসন্ধান
- প্রতিটি গ্রাহকের সাথে একাধিক অভিযোগের ইতিহাস
- অভিযোগ গ্রহণ, দায়িত্ব প্রদান, সমাধান—প্রতিটি সময় সংরক্ষণ
- লাইনম্যান বরাদ্দ এবং লাইনম্যানভিত্তিক রিপোর্ট
- বছরভিত্তিক ও মাসভিত্তিক রিপোর্ট, CSV export, Print/PDF
- Staff role: কেবল নিজের নামে বরাদ্দ অভিযোগ read-only দেখতে পারবে

## গুরুত্বপূর্ণ সিদ্ধান্ত
আপনি বলেছেন আপনি একাই সব entry/update করবেন; তাই staff account-এ complaint/customer write permission দেওয়া হয়নি। লাইনম্যান শুধু নিজের অভিযোগ দেখতে পারবে। পরে চাইলে লাইনম্যানকে সমাধান আপডেট করার ক্ষমতা আলাদাভাবে যোগ করা যাবে।

## সেটআপ (Supabase + GitHub Pages)

1. https://supabase.com এ একটি project তৈরি করুন।
2. Project → SQL Editor → New query খুলে `supabase_setup.sql`-এর সম্পূর্ণ SQL চালান।
3. Authentication → Users থেকে আপনার admin email/password দিয়ে user তৈরি করুন।
4. তৈরি হওয়া user-এর UUID কপি করুন। SQL Editor-এ চালান:
   ```sql
   insert into public.profiles(id, full_name, role)
   values ('আপনার-UUID', 'আপনার নাম', 'admin');
   ```
5. প্রতিটি লাইনম্যানের জন্য Authentication → Users থেকে user তৈরি করুন। তারপর:
   ```sql
   insert into public.profiles(id, full_name, phone, role)
   values ('লাইনম্যানের-UUID', 'লাইনম্যানের নাম', '01XXXXXXXXX', 'staff');
   ```
6. Supabase → Project Settings → API থেকে Project URL এবং `anon` / publishable public key নিন। `service_role` / secret key কখনো ব্যবহার করবেন না।
7. `index.html` ব্রাউজারে খুলুন, URL ও public key বসিয়ে Save করুন।
8. GitHub-এ একটি repository তৈরি করে `index.html` আপলোড করুন। Repository Settings → Pages → Deploy from branch → main / root নির্বাচন করুন। প্রকাশিত URL থেকে লগইন করুন।

## ব্যবহার
- Customers → নতুন গ্রাহক যোগ করে প্রথমে গ্রাহকের তালিকা তৈরি করুন।
- Complaints → নতুন অভিযোগ → ID/ফোন/নাম দিয়ে গ্রাহক নির্বাচন করুন।
- অভিযোগের সময়, মাধ্যম, সমস্যা, লাইনম্যান ও দায়িত্ব দেওয়ার সময় দিন।
- সমাধানের সময় ও সমাধানের বিবরণ পূরণ করে status `সমাধান হয়েছে` করুন।
- Reports থেকে বছর নির্বাচন করে রিপোর্ট দেখুন এবং CSV বা Print/PDF নিন।

## ডেটা ও নিরাপত্তা
- গ্রাহকের ব্যক্তিগত/টেলিকম তথ্য সংবেদনশীল। ব্যবহারের আগে BTCL-এর IT/security/data-retention নীতিমালা ও অনুমোদন যাচাই করুন।
- Supabase project-এ শক্তিশালী password, MFA (যদি উপলব্ধ), নিয়মিত backup এবং সীমিত admin access ব্যবহার করুন।
- Public anon key frontend-এ রাখা স্বাভাবিক, কারণ Row Level Security (RLS) ডেটা রক্ষা করে। `service_role` key কখনো frontend-এ দেবেন না।
- GitHub repository public হলে শুধু code থাকবে; গ্রাহকের ডেটা Supabase-এ থাকবে। কোনো গ্রাহক তথ্য HTML/JS ফাইলে লিখবেন না।
- Staff কেবল নিজের নামে বরাদ্দ অভিযোগের সাথে সম্পর্কিত গ্রাহকের তথ্য পড়তে পারবে; অন্য গ্রাহকের তালিকা দেখতে পারবে না।
- Production-এ ব্যবহারের আগে test data দিয়ে পরীক্ষা করুন। এটি starter application; BTCL-এর অনুমোদিত production system বা official BTCL service নয়।

## সীমাবদ্ধতা / পরবর্তী উন্নয়ন
- Customer import from Excel/CSV এখনো UI-তে নেই; ৩,০০০ গ্রাহক bulk import-এর জন্য Supabase Table Editor → customers → Import data দিয়ে CSV import করতে পারেন (column names SQL schema-এর সাথে মিলতে হবে)।
- complaint event log-এ admin-এর তৈরি/পরিবর্তনের basic event যোগ হয়; পূর্ণ field-by-field audit trail পরবর্তী সংস্করণে যোগ করা উচিত।
- SMS/phone call auto-ingestion নেই; ফোন/SMS থেকে পাওয়া অভিযোগ আপনি হাতে এন্ট্রি করবেন।
