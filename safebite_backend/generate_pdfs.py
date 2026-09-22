import os
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

os.makedirs("docs", exist_ok=True)

styles = getSampleStyleSheet()
title_style = ParagraphStyle(
    'DocTitle',
    parent=styles['Heading1'],
    fontSize=18,
    leading=22,
    textColor=colors.HexColor("#1A365D"),
    spaceAfter=12
)
h2_style = ParagraphStyle(
    'DocH2',
    parent=styles['Heading2'],
    fontSize=14,
    leading=18,
    textColor=colors.HexColor("#2B6CB0"),
    spaceBefore=10,
    spaceAfter=6
)
body_style = ParagraphStyle(
    'DocBody',
    parent=styles['Normal'],
    fontSize=10,
    leading=14,
    textColor=colors.HexColor("#2D3748"),
    spaceAfter=6
)
bullet_style = ParagraphStyle(
    'DocBullet',
    parent=styles['Normal'],
    fontSize=9.5,
    leading=13,
    textColor=colors.HexColor("#2D3748"),
    leftIndent=15,
    firstLineIndent=-10,
    spaceAfter=4
)

# --- PDF 1: WHO Complementary Feeding & Infant Nutrition Guidelines ---
doc1_path = "docs/WHO_Complementary_Feeding_Guidelines.pdf"
doc1 = SimpleDocTemplate(doc1_path, pagesize=letter, leftMargin=40, rightMargin=40, topMargin=40, bottomMargin=40)
story1 = []

story1.append(Paragraph("World Health Organization (WHO) Guidelines on Infant & Toddler Feeding", title_style))
story1.append(Paragraph("Clinical Nutrition and Dietary Safety Standards for Ages 6 to 24 Months", body_style))
story1.append(Spacer(1, 10))

story1.append(Paragraph("1. Core Principles of Safe Complementary Feeding", h2_style))
story1.append(Paragraph("Complementary feeding begins at 6 months when breast milk or formula alone is no longer sufficient to meet nutritional requirements. Foods must be nutrient-dense, easily digestible, and prepared under strict sanitary conditions.", body_style))

story1.append(Paragraph("2. Prohibited and Unsafe Ingredients for Infants (< 12 Months)", h2_style))
story1.append(Paragraph("• <b>Honey:</b> STRICTLY PROHIBITED for all infants under 12 months due to the severe risk of infant botulism caused by Clostridium botulinum spores.", bullet_style))
story1.append(Paragraph("• <b>Added Sugars:</b> No added sugars, syrups, confectionery, or sweetened beverages. High sugar intake alters taste preferences and damages developing dental health.", bullet_style))
story1.append(Paragraph("• <b>Excessive Salt and Sodium:</b> Infant kidneys cannot process high sodium loads. Keep daily salt intake below 1g/day. Processed potato chips, salty snacks, and canned foods are unsafe.", bullet_style))
story1.append(Paragraph("• <b>Cow's Milk as Primary Drink:</b> Unmodified cow's milk should not replace formula or breast milk before 12 months as it lacks sufficient iron and has excessive protein.", bullet_style))
story1.append(Paragraph("• <b>Caffeine & Cocoa (Chocolate):</b> Chocolate contains theobromine and caffeine, which cause cardiovascular stimulation, gastrointestinal distress, and sleep disturbances in babies.", bullet_style))

story1.append(Paragraph("3. Highly Recommended Starter Foods for Babies (6-12 Months)", h2_style))
story1.append(Paragraph("• <b>Banana:</b> 100% natural, smooth texture when mashed. Rich in potassium, vitamin B6, and prebiotic fiber. Easily digested and gentle on infant digestive tracts.", bullet_style))
story1.append(Paragraph("• <b>Sweet Potatoes & Squash:</b> Steamed and pureed. Excellent source of Vitamin A, beta-carotene, and natural carbohydrates.", bullet_style))
story1.append(Paragraph("• <b>Oatmeal & Iron-Fortified Grains:</b> Soft porridge supporting crucial brain and nervous system development.", bullet_style))
story1.append(Paragraph("• <b>Avocado:</b> Healthy monounsaturated fatty acids crucial for rapid neurodevelopment.", bullet_style))

doc1.build(story1)
print(f"✅ Generated {doc1_path}")

# --- PDF 2: CDC & AAP Pediatric Choking Hazards and Additive Safety ---
doc2_path = "docs/CDC_AAP_Choking_Hazards_and_Additives.pdf"
doc2 = SimpleDocTemplate(doc2_path, pagesize=letter, leftMargin=40, rightMargin=40, topMargin=40, bottomMargin=40)
story2 = []

story2.append(Paragraph("CDC & American Academy of Pediatrics (AAP) Food Safety Standards", title_style))
story2.append(Paragraph("Choking Prevention, Food Additives, and Allergen Protocols for Children Under 5", body_style))
story2.append(Spacer(1, 10))

story2.append(Paragraph("1. Primary Choking Hazards for Toddlers and Young Children", h2_style))
story2.append(Paragraph("Choking is a leading cause of unintentional injury in children under 4 years old. Their airways are small and they have not developed mature chewing and swallowing coordination.", body_style))
story2.append(Paragraph("• <b>Whole Grapes and Cherry Tomatoes:</b> High choking risk due to spherical shape and slippery skin. Must always be sliced lengthwise into quarters before serving.", bullet_style))
story2.append(Paragraph("• <b>Hard Nuts and Whole Seeds:</b> Whole peanuts, cashews, and almonds should never be given to toddlers under 4 years. Smooth peanut butter must be thinly spread, never given in large spoonfuls.", bullet_style))
story2.append(Paragraph("• <b>Hot Dogs and Sausage Rounds:</b> Cylindrical shapes can completely occlude the trachea. Must be cut lengthwise then diced.", bullet_style))
story2.append(Paragraph("• <b>Popcorn and Hard Pretzels:</b> Sharp edges and inability to break down easily make them hazardous for children under age 4.", bullet_style))
story2.append(Paragraph("• <b>Raw Hard Vegetables:</b> Whole raw carrots and celery sticks must be cooked until soft or finely grated.", bullet_style))

story2.append(Paragraph("2. Dangerous Chemical Additives and Preservatives", h2_style))
story2.append(Paragraph("• <b>Artificial Synthetic Dyes (Red 40 / Allura Red, Yellow 5 / Tartrazine / E102):</b> Linked in clinical studies to hyperactivity and behavioral disturbances in children. Avoid artificially colored snacks and candies.", bullet_style))
story2.append(Paragraph("• <b>Artificial Sweeteners (Aspartame, Sucralose, Acesulfame Potassium):</b> Unsuitable for pediatric diets; affects gut microbiome development and lacks required caloric nutrition.", bullet_style))
story2.append(Paragraph("• <b>High-Fructose Corn Syrup (HFCS):</b> Causes rapid blood glucose spikes and hepatic lipid accumulation. Should be excluded from infant and toddler products.", bullet_style))
story2.append(Paragraph("• <b>Nitrates and Nitrites:</b> Found in cured meats (bacon, cold cuts). Associated with carcinogenic nitrosamine formation and methemoglobinemia in vulnerable infants.", bullet_style))

doc2.build(story2)
print(f"✅ Generated {doc2_path}")
