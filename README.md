# Christmas Tracker Pro 🎄

A shared, mobile-first Christmas gift tracker with secure separate logins, family recipients, gift statuses, private surprises, and annual spending/count comparisons.

## Setup (about 15–25 minutes)

1. Create a free Supabase project at https://supabase.com/dashboard .
2. Open **SQL Editor**, paste all of `supabase/schema.sql`, and run it once.
3. In Supabase **Authentication → Providers → Email**, keep email/password enabled. By default, users may need to confirm their email before signing in. For production, leave confirmation enabled and configure email delivery as appropriate.
4. Under **Project Settings → API** (or **Connect**), copy the project URL and **publishable/anon** key. Never use the service-role or secret key in a browser app.
5. To test locally: copy `.env.example` to `.env.local`, fill both values, run `npm install` then `npm run dev`.
6. Create a new GitHub repository named `christmas-tracker-pro` and push these files to the `main` branch.
7. In the GitHub repo, go to **Settings → Secrets and variables → Actions** and create repository secrets `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` with the values from step 4.
8. Go to **Settings → Pages**, set **Source** to **GitHub Actions**. Push to main or manually run **Actions → Deploy Christmas Tracker Pro**. The URL will look like `https://YOUR-USERNAME.github.io/christmas-tracker-pro/`.
9. In Supabase **Authentication → URL Configuration**, add the published URL to allowed redirect URLs; configure Site URL to your published URL. This is especially relevant if email confirmations or recovery flows are enabled.
10. Open the app on phone A. Sign up/sign in and **Create family**. In **Family**, copy the invite code and privately share it with phone B. On phone B, sign up with a **different email**, then **Join family** with the code. Both can now manage the same gift list.
11. On iPhone, open the published URL in Safari → Share → Add to Home Screen. On Android, use Chrome → menu → Add to Home screen.

## How it works

- **Gifts**: Choose a Christmas year, add recipients in Family, then add gifts with price, status, link, notes, and private flag.
- **History**: Annual spending and purchased gift counts by year and recipient. Ideas are not counted as spending until marked purchased or later.
- **Family**: Shared recipient list persists across Christmas seasons automatically. No copying needed; adding a recipient is available anytime.
- **Privacy**: Supabase Row Level Security prevents other family members from reading private gifts; their values are also excluded from the other person's totals. Private gifts are accessible to their creator only. Anyone with the invite code can join the household, so share it privately. Shared (non-private) gifts can be edited by either family member.
- **Live updates**: Supabase Realtime subscriptions refresh data when either shopper changes gifts or recipients. Manual refresh is also available.

## Notes

- This is a first version. It does not include receipts, purchase dates, spending budgets, or per-user permission roles.
- A recipient exists across years, and the annual comparison shows totals rather than gift-by-gift history.
- For security, the `gifts` table checks that every recipient belongs to the same household; household creation and joining are performed through authenticated database functions.
- The first version is a responsive web app, not a native iOS/Android app or full offline PWA. Internet access is needed for synchronization.
- To prevent other people from joining, do not share your invite code publicly. Invite-code rotation/revocation is a future enhancement.
