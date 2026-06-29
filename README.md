# 🥗 NutriPlan — Recipe & Meal Planner

A full-stack **Django REST Framework + Angular 17 + Angular Material** application for personalised meal planning powered by a BMI engine, a month-at-a-glance meal calendar, a recipe library, and auto-generated shopping lists.

---

## ✨ Features

| Feature | Details |
|---|---|
| **BMI Calculator** | Mifflin-St Jeor BMR, TDEE, Devine ideal-weight formula, macro breakdown, SVG gauge, meal calorie split |
| **Personalised Calorie Plan** | Daily targets for protein / carbs / fat split by goal (lose / maintain / gain) |
| **Month Calendar** | Click any day to see full meals; auto-generate a whole month in one click |
| **Drag-and-Drop Planner** | CDK DragDrop to reorder or move meals between slots |
| **Recipe Library** | 18 seeded recipes across all meal types; filter by goal, meal type, max calories, tags |
| **Recipe Detail** | Modal with ingredients, macros, step-by-step instructions |
| **Save Recipes** | Many-to-many user ↔ recipe saved bookmarks |
| **Shopping List** | Auto-generated from plan; unit conversion (g/kg), category grouping (produce, dairy, …), check-off progress bar |
| **Continue Watching** | Watch-progress style "today's meals" on dashboard |
| **Auth** | JWT register / login, persistent sessions, guards |
| **Admin** | Django admin for all models |

---

## 🏗 Folder Structure

```
mealplanner/
├── README.md
├── .gitignore
│
├── backend/                         ← Django project
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env.example
│   │
│   ├── mealplanner/                 ← Django project package
│   │   ├── __init__.py
│   │   ├── settings.py              ← JWT, CORS, REST_FRAMEWORK config
│   │   ├── urls.py                  ← Root URL router
│   │   └── wsgi.py
│   │
│   ├── users/                       ← Custom AbstractBaseUser + auth views
│   │   ├── models.py                ← User model
│   │   ├── serializers.py
│   │   ├── views.py                 ← register, login, profile
│   │   └── urls.py
│   │
│   ├── bmi/                         ← BMI calculation engine
│   │   ├── engine.py                ← BMR (Mifflin), TDEE, ideal weight (Devine), macros
│   │   ├── models.py                ← BMIRecord (all calculated fields persisted)
│   │   ├── serializers.py
│   │   ├── views.py                 ← /calculate/, /latest/, /history/
│   │   └── urls.py
│   │
│   ├── recipes/                     ← Recipe + Ingredient many-to-many
│   │   ├── models.py                ← Recipe, Ingredient, RecipeIngredient, Tag
│   │   ├── serializers.py           ← List + Detail serializers
│   │   ├── views.py                 ← CRUD, save toggle, recommended (goal-filtered)
│   │   ├── urls.py
│   │   └── management/commands/
│   │       └── seed_data.py         ← Seeds 50 ingredients, 8 tags, 18 recipes + demo user
│   │
│   ├── meals/                       ← MealPlan + MealEntry calendar
│   │   ├── models.py                ← MealPlan (year/month) + MealEntry (date + slot)
│   │   ├── serializers.py
│   │   ├── views.py                 ← month_plan, auto_generate, reorder (drag-drop), day_nutrition
│   │   └── urls.py
│   │
│   └── shopping/                    ← Shopping list with unit conversion
│       ├── models.py                ← ShoppingList + ShoppingItem
│       ├── views.py                 ← generate_from_plan (deduplication + unit merge)
│       └── urls.py
│
└── frontend/                        ← Angular 17 standalone app
    ├── angular.json
    ├── package.json
    ├── proxy.conf.json              ← /api/* → http://localhost:8000
    ├── tsconfig.json
    ├── tsconfig.app.json
    │
    └── src/
        ├── index.html
        ├── main.ts
        ├── styles.scss              ← Angular Material green theme + CSS tokens
        │
        └── app/
            ├── app.component.ts     ← Root shell (router-outlet only)
            ├── app.config.ts        ← provideRouter, provideHttpClient, authInterceptor
            ├── app.routes.ts        ← Lazy-loaded routes + authGuard / guestGuard
            │
            ├── core/
            │   ├── guards/
            │   │   └── guards.ts            ← authGuard + guestGuard (CanActivateFn)
            │   ├── interceptors/
            │   │   └── auth.interceptor.ts  ← Attaches Bearer token to all requests
            │   └── services/
            │       ├── auth.service.ts      ← JWT login/register, Signal<User>
            │       ├── bmi.service.ts       ← BMI calculate + latest Signal<BMIRecord>
            │       ├── recipe.service.ts    ← CRUD, save toggle, recommended
            │       ├── meal-plan.service.ts ← Month plan, auto-generate, drag-drop reorder
            │       └── shopping.service.ts  ← Generate, toggle, add/delete items
            │
            ├── features/
            │   ├── auth/
            │   │   ├── login/login.component.ts    ← Reactive form + demo fill
            │   │   └── signup/signup.component.ts  ← Register + redirects to /bmi
            │   │
            │   ├── dashboard/
            │   │   └── dashboard.component.ts      ← Overview: BMI stats, today's meals, quick links
            │   │
            │   ├── bmi/
            │   │   └── bmi.component.ts            ← Full calculator: SVG gauge, macros, meal split, tips
            │   │
            │   ├── calendar/
            │   │   └── calendar.component.ts       ← Month grid, day panel, CDK drag-drop, auto-generate
            │   │
            │   ├── recipes/
            │   │   ├── recipes.component.ts        ← Grid, filters, debounced search, save toggle
            │   │   └── recipe-detail-dialog.component.ts  ← Modal: ingredients, instructions, macros
            │   │
            │   └── shopping-list/
            │       └── shopping-list.component.ts  ← Generate, category accordion, check-off, add item
            │
            └── shared/
                ├── components/
                │   └── navbar/
                │       └── navbar.component.ts     ← Sidenav shell + toolbar (acts as layout wrapper)
                └── models/
                    └── models.ts                   ← All TypeScript interfaces + constants
```

---

## 🚀 Setup

### Backend

```bash
cd mealplanner/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Seed database (ingredients, tags, 18 recipes, demo user)
python manage.py seed_data

# Start server
python manage.py runserver
# → http://localhost:8000
```

**Demo account:** `demo@nutriplan.com` / `demo1234`

### Frontend

```bash
cd mealplanner/frontend

npm install
npm start
# → http://localhost:4200
```

---

## 📡 API Endpoints

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register/` | Register new user, returns JWT |
| POST | `/api/auth/login/` | Login, returns JWT |
| POST | `/api/auth/refresh/` | Refresh access token |
| GET/PUT | `/api/auth/me/` | Get or update profile |

### BMI
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/bmi/calculate/` | Full BMI calculation + persists record |
| GET | `/api/bmi/latest/` | Most recent BMI record for user |
| GET | `/api/bmi/history/` | Last 10 BMI records |

### Recipes
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/recipes/` | List all (filterable by meal_type, goal, max_calories, search) |
| GET | `/api/recipes/<id>/` | Recipe detail with ingredients |
| POST/DELETE | `/api/recipes/<id>/save/` | Toggle saved |
| GET | `/api/recipes/saved/` | User's saved recipes |
| GET | `/api/recipes/recommended/?meal_type=lunch` | Goal-aware recommendations |
| GET | `/api/recipes/ingredients/?q=chicken` | Ingredient autocomplete |

### Meals
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/meals/month/<year>/<month>/` | Full calendar data for the month |
| POST | `/api/meals/month/<year>/<month>/auto-generate/` | Auto-fill whole month with BMI-matched recipes |
| GET/POST | `/api/meals/plans/` | List / create plans |
| POST | `/api/meals/plans/<id>/entries/` | Add a meal entry |
| PUT/DELETE | `/api/meals/entries/<id>/` | Edit or delete entry |
| POST | `/api/meals/plans/<id>/reorder/` | Drag-and-drop reorder |
| GET | `/api/meals/plans/<id>/day/<date>/` | Day nutrition summary |

### Shopping
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/shopping/generate/<plan_id>/` | Auto-generate from meal plan (with unit merging) |
| GET | `/api/shopping/` | All user's shopping lists |
| PATCH | `/api/shopping/items/<id>/toggle/` | Check / uncheck item |
| POST | `/api/shopping/<list_id>/items/` | Add manual item |
| DELETE | `/api/shopping/items/<id>/` | Delete item |

---

## 🧠 Architecture Highlights

### Django
- **Custom User** — `AbstractBaseUser` with email as `USERNAME_FIELD`
- **BMI Engine** (`bmi/engine.py`) — pure functions for Mifflin-St Jeor BMR, TDEE, Devine ideal weight, macro split; all results stored on `BMIRecord` for history
- **Many-to-many** — `Recipe ↔ Ingredient` via `RecipeIngredient` through-model (quantity + unit); `Recipe ↔ User` for saved recipes; `Recipe ↔ Tag`
- **Unit conversion** (`shopping/views.py`) — `UNIT_TO_G` map merges ingredient quantities across recipes before writing to `ShoppingItem`
- **Auto-generate** — fills every day × every slot for the month using goal-matched recipe queryset

### Angular
- **Standalone components** throughout; no NgModules
- **Signals** for all local state (`signal<BMIRecord | null>`)
- **Lazy-loaded routes** via `loadComponent`
- **Functional guards** — `authGuard` / `guestGuard` (CanActivateFn)
- **HTTP Interceptor** — `authInterceptor` (HttpInterceptorFn) attaches Bearer token
- **CDK DragDrop** — meal entries draggable between slots; `reorderEntries` API call on drop
- **Debounced search** — `Subject` + `debounceTime(300)` + `distinctUntilChanged()`
- **Angular Material** — sidenav, toolbar, cards, dialogs, expansion panels, progress bars, chips, checkboxes, snackbars

---

## 🎨 Design Tokens

| Token | Value | Usage |
|---|---|---|
| `--primary` | `#43a047` | Green — buttons, active nav, accents |
| `--primary-dark` | `#2e7d32` | Hover states |
| `--primary-light` | `#e8f5e9` | Backgrounds, badges |
| `--accent` | `#00897b` | Teal — secondary accent |
| `--bg` | `#f5f7f5` | Page background |
| `--radius` | `14px` | Card border radius |
| Font display | Poppins 600–800 | Headings |
| Font body | Inter 300–600 | All UI text |

---

## 🏥 BMI Calculation Reference

| Formula | Used for |
|---|---|
| **Mifflin-St Jeor** | Basal Metabolic Rate (BMR) |
| **Harris-Benedict multiplier** | TDEE from activity level |
| **Devine formula** | Ideal weight range |
| **±500 kcal offset** | Calorie target by goal |
| **Macro split** | Lose: 35/40/25 · Maintain: 30/45/25 · Gain: 30/50/20 |

---

## 🔧 Production Checklist

- [ ] Set `SECRET_KEY` from environment variable
- [ ] Set `DEBUG=False`
- [ ] Replace SQLite with PostgreSQL (`DATABASE_URL`)
- [ ] Run `python manage.py collectstatic`
- [ ] Serve with gunicorn + nginx
- [ ] Build Angular: `npm run build` → serve `dist/` from nginx
- [ ] Set `CORS_ALLOWED_ORIGINS` to production domain
