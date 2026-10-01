"""
PadosiPro Backend — Seed script: categories & sub-services matching app.padosipro.com
Run: python -m src.seed
"""
import asyncio
from sqlalchemy import select, delete
from .database import AsyncSessionLocal, create_tables
from .models import Category, Task

SEED_DATA = [
    {
        "name": "Errands & Daily Tasks",
        "subtitle": "Bills, banks, documents, government work",
        "icon": "checklist",
        "is_coming_soon": False,
        "order": 1,
        "tasks": [
            ("Pickups & Deliveries", "Drop-off and pick-up of packages, keys, parcels, laundry and essentials."),
            ("Payments & Renewals", "Electricity, water, gas, property tax and license renewals handled."),
            ("Documents & Government", "Passport assistance, Aadhaar updates, notary and affidavits."),
            ("Shopping", "Local market runs, specialty store purchases and bulk supplies."),
        ],
    },
    {
        "name": "Home Services",
        "subtitle": "AC, plumbing, electrical, cleaning, repairs",
        "icon": "home",
        "is_coming_soon": False,
        "order": 2,
        "tasks": [
            ("Cleaning", "Deep cleaning, kitchen degreasing, bathroom scrubbing and sofa shampooing."),
            ("Repairs", "Plumbing leaks, switch replacements, carpentry and minor touch-ups."),
            ("Appliances & Utilities", "AC servicing, RO filter change, washing machine and chimney repair."),
            ("Property & Society", "Society maintenance, tenant handover and property management."),
        ],
    },
    {
        "name": "Travel & Tourism",
        "subtitle": "Flights, hotels, visas, transfers, itineraries",
        "icon": "location",
        "is_coming_soon": False,
        "order": 3,
        "tasks": [
            ("Book Travel", "Flight tickets, train bookings, premium cabs and boutique stays."),
            ("On-Trip Support", "Real-time itinerary changes, local reservations and emergencies."),
            ("Documents & Visa", "Visa filing, document attestation and travel insurance."),
            ("Local Transport", "Airport transfers, daily driver coordination and rental cars."),
        ],
    },
    {
        "name": "Health & Medical",
        "subtitle": "Doctor visits, pharmacy, labs, physio",
        "icon": "heart",
        "is_coming_soon": False,
        "order": 4,
        "tasks": [
            ("Appointments & Tests", "Specialist consultations, lab tests at home and diagnostic scans."),
            ("Records & Reports", "Digitalising medical history, prescriptions and test trends."),
            ("Hospital & Emergency", "Ambulance coordination, hospital admission and discharge support."),
            ("Insurance & Claims", "TPA cashless coordination and health claim documentation."),
        ],
    },
    {
        "name": "Senior Care",
        "subtitle": "Check-ins, medicines, vitals, companionship",
        "icon": "senior",
        "is_coming_soon": False,
        "order": 5,
        "tasks": [
            ("Daily Care", "Scheduled home check-ins, routine assistance and friendly visits."),
            ("Medical Support", "Physiotherapy at home, nursing attendants and vitals monitoring."),
            ("Safety & Mobility", "Grab rails, non-slip flooring and mobility equipment setup."),
            ("Family Coordination", "Daily reports, prescription updates and family sync calls."),
        ],
    },
    {
        "name": "Events & Management",
        "subtitle": "Weddings, décor, catering, photography",
        "icon": "event",
        "is_coming_soon": False,
        "order": 6,
        "tasks": [
            ("Planning & Venue", "Milestone birthdays, anniversaries and intimate wedding ceremonies."),
            ("Vendors & Services", "Curated caterers, florists, balloon stylists and sound setup."),
            ("Guests", "RSVP management, welcome hampers and guest transit coordination."),
            ("Event Day & After", "On-ground management, cleanup and return of rented supplies."),
        ],
    },
    {
        "name": "Workforce Management",
        "subtitle": "Maids, cooks, drivers, nannies, payroll",
        "icon": "workforce",
        "is_coming_soon": False,
        "order": 7,
        "tasks": [
            ("Hire Staff", "Sourcing trusted domestic help, cooks, chauffeurs and babysitters."),
            ("Staff Records & Payroll", "Attendance tracking, monthly wage distribution and advances."),
            ("Verification", "Police verification, Aadhaar KYC and background reference checks."),
            ("Replacement & Exit", "Quick replacement handling, full and final settlements."),
        ],
    },
    {
        "name": "Digital & Tech Help",
        "subtitle": "WiFi, CCTV, smart locks, device repair",
        "icon": "tech",
        "is_coming_soon": False,
        "order": 8,
        "tasks": [
            ("Device Setup", "Smart TV, soundbars, mesh WiFi, laptops and printer configurations."),
            ("Internet & Home Tech", "CCTV security cameras, smart video doorbells and smart locks."),
            ("Accounts & Data", "Cloud backups, password recovery and email setup."),
            ("Safety & Support", "Parental controls, anti-virus and home network diagnostics."),
        ],
    },
    {
        "name": "Relocation Services",
        "subtitle": "Packers, movers, handover, paperwork",
        "icon": "relocation",
        "is_coming_soon": False,
        "order": 9,
        "tasks": [
            ("Find a Home", "Shortlisting verified rental apartments and coordinating visits."),
            ("Move Execution", "Packing, loading, insured transport and unpacking coordination."),
            ("Set Up New Home", "Unpacking, appliance installation, deep cleaning and painting."),
            ("Transfers & Paperwork", "Gas connection transfer, society NOC and address updates."),
        ],
    },
    {
        "name": "NutriFix",
        "subtitle": "Groceries, food delivery, diet plans, meal prep",
        "icon": "food",
        "is_coming_soon": True,
        "order": 10,
        "tasks": [
            ("Diet Plans", "Customised nutritionist-backed meal guidelines."),
            ("Meal Delivery", "Home-cooked healthy tiffin subscription."),
            ("Groceries", "Farm-fresh organic vegetables, cold-pressed oils and pantry staples."),
            ("Special & Corporate", "Post-surgery recovery diets, diabetic-friendly meal plans."),
        ],
    },
    {
        "name": "Fashion & Styling",
        "subtitle": "Salon at home, tailoring, styling, gifting",
        "icon": "fashion",
        "is_coming_soon": True,
        "order": 11,
        "tasks": [
            ("Styling", "Wardrobe audit, personal shopping and event styling."),
            ("Tailoring & Alterations", "Doorstep measurement, blouse stitching and suit fitting."),
            ("Sourcing", "Handcrafted sarees, custom fabrics and ethnic jewelry."),
            ("Garment Care", "Dry cleaning, leather polishing and heirloom saree restoration."),
        ],
    },
    {
        "name": "Religious & Cultural",
        "subtitle": "Pandit booking, puja, temple visits",
        "icon": "religious",
        "is_coming_soon": True,
        "order": 12,
        "tasks": [
            ("Pooja & Priest", "Griha Pravesh, Satyanarayan, Vastu and Havan ceremonies."),
            ("Festivals & Rituals", "Diwali, Ganesh Chaturthi, Navratri and Chhath preparations."),
            ("Materials & Offerings", "Samagri kits, pure ghee, brass idols and fresh flowers."),
            ("Pilgrimage & Community", "VIP darshan, temple visits and community bhandara support."),
        ],
    },
    {
        "name": "Business Support",
        "subtitle": "Registration, GST, bookkeeping, compliance",
        "icon": "business",
        "is_coming_soon": True,
        "order": 13,
        "tasks": [
            ("Company Setup", "Pvt Ltd, LLP, trademark filing and shop establishment."),
            ("Tax & Compliance", "GST monthly returns, TDS filing and annual IT returns."),
            ("Documents & Legal", "Founder agreements, vendor contracts and NDA drafting."),
            ("Office Admin", "Coworking desk booking, pantry supplies and IT assets."),
        ],
    },
    {
        "name": "Education Support",
        "subtitle": "Tutors, admissions, exam prep",
        "icon": "education",
        "is_coming_soon": True,
        "order": 14,
        "tasks": [
            ("Tutors & Classes", "Verified home tutors for ICSE, CBSE, IB and languages."),
            ("Admissions", "School application forms, documentation and interview guidance."),
            ("Exams & Forms", "Olympiad registrations, competitive test prep guidance."),
            ("Courses & Career", "Higher studies abroad counseling and resume reviews."),
        ],
    },
    {
        "name": "Insurance & Loans",
        "subtitle": "Compare policies, plan loans, paperwork handled",
        "icon": "finance",
        "is_coming_soon": True,
        "order": 15,
        "tasks": [
            ("Health insurance", "Family floater and super top-up comparison."),
            ("Life insurance", "Term insurance advisory and nomination update."),
            ("Vehicle insurance", "Instant car and bike policy renewal."),
            ("Personal loan", "Low interest rate documentation support."),
            ("Home loan", "Balance transfer and new property sanctioning."),
        ],
    },
]


async def seed() -> None:
    await create_tables()
    async with AsyncSessionLocal() as db:
        # Check if already seeded with new categories
        result = await db.execute(select(Category).where(Category.name == "NutriFix"))
        if result.scalar_one_or_none():
            print("✅ Database already seeded with complete catalogue.")
            return

        print("🌱 Seeding database with complete catalogue...")
        # Clear existing old categories & tasks if any
        await db.execute(delete(Task))
        await db.execute(delete(Category))

        for cat_data in SEED_DATA:
            cat = Category(
                name=cat_data["name"],
                subtitle=cat_data["subtitle"],
                icon=cat_data["icon"],
                is_coming_soon=cat_data["is_coming_soon"],
                order=cat_data["order"],
            )
            db.add(cat)
            await db.flush()

            for task_name, task_desc in cat_data["tasks"]:
                db.add(Task(name=task_name, description=task_desc, category_id=cat.id))

        await db.commit()
        print(f"✅ Seeded {sum(len(c['tasks']) for c in SEED_DATA)} tasks across {len(SEED_DATA)} categories.")


if __name__ == "__main__":
    asyncio.run(seed())
