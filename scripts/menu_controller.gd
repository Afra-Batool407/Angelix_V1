@tool
extends CanvasLayer
## Linear menu flow: subjects -> chapters -> chapter topics -> 3D terrain.
## State 0 = subjects, State 1 = chapters, State 2 = topics.
##
## Curriculum data is transcribed from two PCTB grade-9 textbooks
## (Punjab Curriculum and Textbook Board, Lahore), extracted via OCR:
## - Mathematics-9: page1-150.pdf + page151-288.pdf (288 scanned pages, 13 units)
## - Computer Science and Entrepreneurship-9:
##   "PCTB Books/New 9 Computer EM Full Book Punjab.pdf" (264 scanned pages, 12 units)
## Source PDFs: https://github.com/Afra-Batool407/PCTB-Books

enum MenuState { SUBJECTS = 0, CHAPTERS = 1, TOPICS = 2 }

# ---------------------------------------------------------------
# Global configuration matrix (PCTB grade-9, exact book order)
# IDs are stable (math.uXX.[topic-slug] / cs.uXX.[topic-slug]) and
# separate from display titles; locked entries are content not yet
# built for the 3D world.
# ---------------------------------------------------------------
const SUBJECTS := [
	{"id": "math", "title": "Math", "subtitle": "13 units", "enabled": true},
	{"id": "computer-science", "title": "Computer Science", "subtitle": "12 units", "enabled": true},
	{"id": "physics", "title": "Physics", "subtitle": "Coming soon", "enabled": false},
	{"id": "chemistry", "title": "Chemistry", "subtitle": "Coming soon", "enabled": false},
	{"id": "biology", "title": "Biology", "subtitle": "Coming soon", "enabled": false},
	{"id": "english", "title": "English", "subtitle": "Coming soon", "enabled": false},
	{"id": "urdu", "title": "Urdu", "subtitle": "Coming soon", "enabled": false},
	{"id": "islamiat", "title": "Islamiat", "subtitle": "Coming soon", "enabled": false},
	{"id": "pak-studies", "title": "Pak Studies", "subtitle": "Coming soon", "enabled": false},
]

const MATH_CHAPTERS := [
	{"id": "math.u01", "title": "Unit 1", "subtitle": "Real Numbers", "enabled": true},
	{"id": "math.u02", "title": "Unit 2", "subtitle": "Logarithms", "enabled": true},
	{"id": "math.u03", "title": "Unit 3", "subtitle": "Sets and Functions", "enabled": true},
	{"id": "math.u04", "title": "Unit 4", "subtitle": "Factorization and Algebraic Manipulation", "enabled": true},
	{"id": "math.u05", "title": "Unit 5", "subtitle": "Linear Equations and Inequalities", "enabled": true},
	{"id": "math.u06", "title": "Unit 6", "subtitle": "Trigonometry", "enabled": true},
	{"id": "math.u07", "title": "Unit 7", "subtitle": "Coordinate Geometry", "enabled": true},
	{"id": "math.u08", "title": "Unit 8", "subtitle": "Logic", "enabled": true},
	{"id": "math.u09", "title": "Unit 9", "subtitle": "Similar Figures", "enabled": true},
	{"id": "math.u10", "title": "Unit 10", "subtitle": "Graphs of Functions", "enabled": true},
	{"id": "math.u11", "title": "Unit 11", "subtitle": "Loci and Construction", "enabled": true},
	{"id": "math.u12", "title": "Unit 12", "subtitle": "Information Handling", "enabled": true},
	{"id": "math.u13", "title": "Unit 13", "subtitle": "Probability", "enabled": true},
]

const UNIT1_TOPICS := [
	{"id": "math.u01.real-numbers", "title": "1.1 Introduction to Real Numbers", "subtitle": "Section 1.1 - Open Lesson", "enabled": true},
	{"id": "math.u01.real-numbers.rational-irrational-combination", "title": "Combination of Rational and Irrational Numbers", "subtitle": "Section 1.1.1 - Open 3D World", "enabled": true},
	{"id": "math.u01.real-numbers.decimal-rational", "title": "Decimal Representation of Rational Numbers", "subtitle": "Section 1.1.2", "enabled": false},
	{"id": "math.u01.real-numbers.decimal-irrational", "title": "Decimal Representation of Irrational Numbers", "subtitle": "Section 1.1.3", "enabled": false},
	{"id": "math.u01.real-numbers.number-line", "title": "Representation of Rational and Irrational Numbers on Number Line", "subtitle": "Section 1.1.4", "enabled": false},
	{"id": "math.u01.real-numbers.properties", "title": "Properties of Real Numbers", "subtitle": "Section 1.1.5", "enabled": false},
	{"id": "math.u01.radical-expressions", "title": "1.2 Radical Expressions", "subtitle": "Section 1.2", "enabled": false},
	{"id": "math.u01.radical-expressions.laws-radicals-indices", "title": "Laws of Radicals and Indices", "subtitle": "Section 1.2.1", "enabled": false},
	{"id": "math.u01.radical-expressions.surds", "title": "Surds and their Applications", "subtitle": "Section 1.2.2", "enabled": false},
	{"id": "math.u01.radical-expressions.rationalization", "title": "Rationalization of Denominator", "subtitle": "Section 1.2.3", "enabled": false},
	{"id": "math.u01.real-numbers-applications", "title": "1.3 Application of Real Numbers in Daily Life", "subtitle": "Section 1.3", "enabled": false},
	{"id": "math.u01.real-numbers-applications.temperature", "title": "Temperature Conversions", "subtitle": "Section 1.3.1", "enabled": false},
	{"id": "math.u01.real-numbers-applications.profit-loss", "title": "Profit and Loss", "subtitle": "Section 1.3.2", "enabled": false},
	{"id": "math.u01.ex-1.1", "title": "Exercise 1.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u01.ex-1.2", "title": "Exercise 1.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u01.ex-1.3", "title": "Exercise 1.3", "subtitle": "Practice", "enabled": false},
	{"id": "math.u01.review", "title": "Review Exercise 1", "subtitle": "Unit review", "enabled": false},
]

const UNIT2_TOPICS := [
	{"id": "math.u02.scientific-notation", "title": "2.1 Scientific Notation", "subtitle": "Section 2.1", "enabled": false},
	{"id": "math.u02.scientific-notation.ordinary-to-scientific", "title": "Conversion of Numbers from Ordinary Notation to Scientific Notation", "subtitle": "Section 2.1.1", "enabled": false},
	{"id": "math.u02.scientific-notation.scientific-to-ordinary", "title": "Conversion of Numbers from Scientific Notation to Ordinary Notation", "subtitle": "Section 2.1.2", "enabled": false},
	{"id": "math.u02.logarithm", "title": "2.2 Logarithm", "subtitle": "Section 2.2", "enabled": false},
	{"id": "math.u02.logarithm.real-number", "title": "Logarithm of a Real Number", "subtitle": "Section 2.2.1", "enabled": false},
	{"id": "math.u02.common-logarithm", "title": "2.3 Common Logarithm", "subtitle": "Section 2.3", "enabled": false},
	{"id": "math.u02.common-logarithm.characteristic-mantissa", "title": "Characteristic and Mantissa of Logarithms", "subtitle": "Section 2.3.1", "enabled": false},
	{"id": "math.u02.common-logarithm.finding", "title": "Finding Common Logarithm of a Number", "subtitle": "Section 2.3.2", "enabled": false},
	{"id": "math.u02.common-logarithm.antilogarithm", "title": "Concept of Antilogarithm", "subtitle": "Section 2.3.3", "enabled": false},
	{"id": "math.u02.common-logarithm.natural", "title": "Natural Logarithm", "subtitle": "Section 2.3.4", "enabled": false},
	{"id": "math.u02.laws-logarithm", "title": "2.4 Laws of Logarithm", "subtitle": "Section 2.4", "enabled": false},
	{"id": "math.u02.laws-logarithm.applications", "title": "Applications of Logarithm", "subtitle": "Section 2.4.1", "enabled": false},
	{"id": "math.u02.ex-2.3", "title": "Exercise 2.3", "subtitle": "Practice", "enabled": false},
	{"id": "math.u02.ex-2.4", "title": "Exercise 2.4", "subtitle": "Practice", "enabled": false},
	{"id": "math.u02.review", "title": "Review Exercise 2", "subtitle": "Unit review", "enabled": false},
]

const UNIT3_TOPICS := [
	{"id": "math.u03.patterns-structures-relationships", "title": "3.1 Mathematics as the Study of Patterns, Structures and Relationships", "subtitle": "Section 3.1", "enabled": false},
	{"id": "math.u03.patterns-structures-relationships.basic-definitions", "title": "Basic Definitions", "subtitle": "Section 3.1.1", "enabled": false},
	{"id": "math.u03.operations-on-sets", "title": "3.2 Operations on Sets", "subtitle": "Section 3.2", "enabled": false},
	{"id": "math.u03.operations-on-sets.venn-diagram", "title": "Identification of Sets Using Venn Diagram", "subtitle": "Section 3.2.1", "enabled": false},
	{"id": "math.u03.operations-on-sets.three-sets", "title": "Operations on Three Sets", "subtitle": "Section 3.2.2", "enabled": false},
	{"id": "math.u03.operations-on-sets.real-world-applications", "title": "Real-World Applications", "subtitle": "Section 3.2.3", "enabled": false},
	{"id": "math.u03.binary-relations", "title": "3.3 Binary Relations", "subtitle": "Section 3.3", "enabled": false},
	{"id": "math.u03.binary-relations.table-ordered-pair-graphs", "title": "Relation as Table, Ordered Pair and Graphs", "subtitle": "Section 3.3.1", "enabled": false},
	{"id": "math.u03.binary-relations.domain-range", "title": "Function and its Domain and Range", "subtitle": "Section 3.3.2", "enabled": false},
	{"id": "math.u03.binary-relations.notation", "title": "Notation of Function", "subtitle": "Section 3.3.3", "enabled": false},
	{"id": "math.u03.binary-relations.linear-quadratic-functions", "title": "Linear and Quadratic Functions", "subtitle": "Section 3.3.4", "enabled": false},
	{"id": "math.u03.ex-3.1", "title": "Exercise 3.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u03.ex-3.2", "title": "Exercise 3.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u03.ex-3.3", "title": "Exercise 3.3", "subtitle": "Practice", "enabled": false},
	{"id": "math.u03.review", "title": "Review Exercise 3", "subtitle": "Unit review", "enabled": false},
]

const UNIT4_TOPICS := [
	{"id": "math.u04.identifying-common-factors-trinomials", "title": "4.1 Identifying Common Factors and Trinomials Concretely, Pictorially and Symbolically", "subtitle": "Section 4.1", "enabled": false},
	{"id": "math.u04.identifying-common-factors-trinomials.common-factors", "title": "Common Factors", "subtitle": "Section 4.1.1", "enabled": false},
	{"id": "math.u04.identifying-common-factors-trinomials.trinomial-factoring", "title": "Trinomial Factoring", "subtitle": "Section 4.1.2", "enabled": false},
	{"id": "math.u04.identifying-common-factors-trinomials.quadratic-cubic", "title": "Factorizing Quadratic and Cubic Algebraic Expressions", "subtitle": "Section 4.1.3", "enabled": false},
	{"id": "math.u04.factorization-special-types", "title": "4.2 Factorization of a^4 + a^2*b^2 + b^4 or a^4 + b^4", "subtitle": "Section 4.2", "enabled": false},
	{"id": "math.u04.hcf-lcm", "title": "4.3 Highest Common Factor (HCF) and Least Common Multiple (LCM)", "subtitle": "Section 4.3", "enabled": false},
	{"id": "math.u04.hcf-lcm.hcf", "title": "Highest Common Factor (HCF)", "subtitle": "Section 4.3.1", "enabled": false},
	{"id": "math.u04.hcf-lcm.lcm", "title": "Least Common Multiple (LCM)", "subtitle": "Section 4.3.2", "enabled": false},
	{"id": "math.u04.hcf-lcm.relationship", "title": "Relationship Between LCM and HCF", "subtitle": "Section 4.3.3", "enabled": false},
	{"id": "math.u04.square-root", "title": "4.4 Square Root of an Algebraic Expression", "subtitle": "Section 4.4", "enabled": false},
	{"id": "math.u04.square-root.real-world-problems", "title": "Real World Problems of Factorization", "subtitle": "Section 4.4.1", "enabled": false},
	{"id": "math.u04.ex-4.1", "title": "Exercise 4.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u04.ex-4.2", "title": "Exercise 4.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u04.review", "title": "Review Exercise 4", "subtitle": "Unit review", "enabled": false},
]

const UNIT5_TOPICS := [
	{"id": "math.u05.linear-equation", "title": "5.1 Linear Equation", "subtitle": "Section 5.1", "enabled": false},
	{"id": "math.u05.linear-equation.one-variable", "title": "Solving a Linear Equation in One Variable", "subtitle": "Section 5.1.1", "enabled": false},
	{"id": "math.u05.linear-inequalities", "title": "5.2 Linear Inequalities", "subtitle": "Section 5.2", "enabled": false},
	{"id": "math.u05.linear-inequalities.two-variables", "title": "Solution of a Linear Inequality in Two Variables", "subtitle": "Section 5.2.1", "enabled": false},
	{"id": "math.u05.linear-inequalities.system", "title": "Solution of Two Linear Inequalities in Two Variables", "subtitle": "Section 5.2.2", "enabled": false},
	{"id": "math.u05.feasible-solution", "title": "5.3 Feasible Solution", "subtitle": "Section 5.3", "enabled": false},
	{"id": "math.u05.feasible-solution.region", "title": "Solution Region of a System of Linear Inequalities", "subtitle": "Section 5.3.1", "enabled": false},
	{"id": "math.u05.feasible-solution.max-min", "title": "Maximum and Minimum Values of a Function in the Feasible Region", "subtitle": "Section 5.3.2", "enabled": false},
	{"id": "math.u05.ex-5.1", "title": "Exercise 5.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u05.ex-5.2", "title": "Exercise 5.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u05.ex-5.3", "title": "Exercise 5.3", "subtitle": "Practice", "enabled": false},
	{"id": "math.u05.review", "title": "Review Exercise 5", "subtitle": "Unit review", "enabled": false},
]

const UNIT6_TOPICS := [
	{"id": "math.u06.identifying-angles-standard-position", "title": "6.1 Identifying Angles in Standard Position", "subtitle": "Section 6.1", "enabled": false},
	{"id": "math.u06.identifying-angles-standard-position.degree-measurement", "title": "Degree Measurement", "subtitle": "Section 6.1.1", "enabled": false},
	{"id": "math.u06.identifying-angles-standard-position.deg-min-sec", "title": "Converting Degrees to Minutes and Seconds", "subtitle": "Section 6.1.2", "enabled": false},
	{"id": "math.u06.identifying-angles-standard-position.decimal-degrees", "title": "Converting from Degrees, Minutes and Seconds to Decimal Degrees", "subtitle": "Section 6.1.3", "enabled": false},
	{"id": "math.u06.identifying-angles-standard-position.radian", "title": "Circular Measure (Radian)", "subtitle": "Section 6.1.4", "enabled": false},
	{"id": "math.u06.trigonometric-ratios", "title": "6.2 Trigonometric Ratios", "subtitle": "Section 6.2", "enabled": false},
	{"id": "math.u06.trigonometric-ratios.acute-angle", "title": "Trigonometric Ratios of an Acute Angle", "subtitle": "Section 6.2.1", "enabled": false},
	{"id": "math.u06.trigonometric-ratios.complementary", "title": "Trigonometric Ratios of Complementary Angles", "subtitle": "Section 6.2.2", "enabled": false},
	{"id": "math.u06.trigonometric-identities", "title": "6.3 Trigonometric Identities", "subtitle": "Section 6.3", "enabled": false},
	{"id": "math.u06.special-angles", "title": "6.4 Values of Trigonometric Ratios of Special Angles", "subtitle": "Section 6.4", "enabled": false},
	{"id": "math.u06.solution-of-triangle", "title": "6.5 Solution of a Triangle", "subtitle": "Section 6.5", "enabled": false},
	{"id": "math.u06.elevation-depression", "title": "6.6 The Angle of Elevation and the Angle of Depression", "subtitle": "Section 6.6", "enabled": false},
	{"id": "math.u06.ex-6.1", "title": "Exercise 6.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u06.ex-6.4", "title": "Exercise 6.4", "subtitle": "Practice", "enabled": false},
	{"id": "math.u06.review", "title": "Review Exercise 6", "subtitle": "Unit review", "enabled": false},
]

const UNIT7_TOPICS := [
	{"id": "math.u07.coordinate-plane", "title": "7.1 Coordinate Plane", "subtitle": "Section 7.1", "enabled": false},
	{"id": "math.u07.coordinate-plane.distance-formula", "title": "The Distance Formula", "subtitle": "Section 7.1.1", "enabled": false},
	{"id": "math.u07.coordinate-plane.midpoint-formula", "title": "Midpoint Formula", "subtitle": "Section 7.1.2", "enabled": false},
	{"id": "math.u07.slope-gradient", "title": "7.2 Slope or Gradient of a Line", "subtitle": "Section 7.2", "enabled": false},
	{"id": "math.u07.slope-gradient.two-points", "title": "Slope or Gradient of a Straight Line Joining Two Points", "subtitle": "Section 7.2.1", "enabled": false},
	{"id": "math.u07.slope-gradient.parallel-x-axis", "title": "Equation of a Straight Line Parallel to the x-axis", "subtitle": "Section 7.2.2", "enabled": false},
	{"id": "math.u07.slope-gradient.parallel-y-axis", "title": "Equation of a Straight Line Parallel to the y-axis", "subtitle": "Section 7.2.3", "enabled": false},
	{"id": "math.u07.slope-gradient.standard-forms", "title": "Standard Forms of Equation of Straight Line", "subtitle": "Section 7.2.4", "enabled": false},
	{"id": "math.u07.slope-gradient.linear-two-variables", "title": "A Linear Equation in Two Variables Represents a Straight Line", "subtitle": "Section 7.2.5", "enabled": false},
	{"id": "math.u07.slope-gradient.general-to-standard", "title": "Transform the General Linear Equation to Standard Forms", "subtitle": "Section 7.2.6", "enabled": false},
	{"id": "math.u07.applications", "title": "7.3 Applications of Coordinate Geometry in Real Life", "subtitle": "Section 7.3", "enabled": false},
	{"id": "math.u07.ex-7.1", "title": "Exercise 7.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u07.ex-7.2", "title": "Exercise 7.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u07.review", "title": "Review Exercise 7", "subtitle": "Unit review", "enabled": false},
]

const UNIT8_TOPICS := [
	{"id": "math.u08.statement", "title": "8.1 Statement", "subtitle": "Section 8.1", "enabled": false},
	{"id": "math.u08.statement.logical-operators", "title": "Logical Operators", "subtitle": "Section 8.1.1", "enabled": false},
	{"id": "math.u08.statement.symbols", "title": "Explanation of the Use of the Symbols", "subtitle": "Section 8.1.2", "enabled": false},
	{"id": "math.u08.statement.mathematical-proof", "title": "Mathematical Proof", "subtitle": "Section 8.1.3", "enabled": false},
	{"id": "math.u08.statement.theorem-conjecture-axiom", "title": "Theorem, Conjecture and Axiom", "subtitle": "Section 8.1.4", "enabled": false},
	{"id": "math.u08.statement.deductive-proof", "title": "Deductive Proof", "subtitle": "Section 8.1.5", "enabled": false},
	{"id": "math.u08.ex-8.1", "title": "Exercise 8.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u08.review", "title": "Review Exercise 8", "subtitle": "Unit review", "enabled": false},
]

const UNIT9_TOPICS := [
	{"id": "math.u09.similarity-of-polygons", "title": "9.1 Similarity of Polygons", "subtitle": "Section 9.1", "enabled": false},
	{"id": "math.u09.similarity-of-polygons.similar-triangles", "title": "Identification of Similar Triangles", "subtitle": "Section 9.1.1", "enabled": false},
	{"id": "math.u09.similarity-of-polygons.quadrilaterals", "title": "Similarity of Quadrilaterals", "subtitle": "Section 9.1.2", "enabled": false},
	{"id": "math.u09.area-similar-figures", "title": "9.2 Area of Similar Figures", "subtitle": "Section 9.2", "enabled": false},
	{"id": "math.u09.volume-similar-solids", "title": "9.3 Volume of Similar Solids", "subtitle": "Section 9.3", "enabled": false},
	{"id": "math.u09.polygon-properties", "title": "9.4 Geometrical Properties of Polygon and their Applications", "subtitle": "Section 9.4", "enabled": false},
	{"id": "math.u09.polygon-properties.regular-polygon", "title": "Geometrical Properties of Regular Polygon", "subtitle": "Section 9.4.1", "enabled": false},
	{"id": "math.u09.polygon-properties.triangle", "title": "Geometrical Properties of Triangle", "subtitle": "Section 9.4.2", "enabled": false},
	{"id": "math.u09.polygon-properties.parallelogram", "title": "Geometrical Properties of Parallelogram", "subtitle": "Section 9.4.3", "enabled": false},
	{"id": "math.u09.polygon-properties.applications", "title": "Applications of Polygons", "subtitle": "Section 9.4.4", "enabled": false},
	{"id": "math.u09.ex-9.4", "title": "Exercise 9.4", "subtitle": "Practice", "enabled": false},
	{"id": "math.u09.review", "title": "Review Exercise 9", "subtitle": "Unit review", "enabled": false},
]

const UNIT10_TOPICS := [
	{"id": "math.u10.functions-graphs", "title": "10.1 Functions and their Graphs", "subtitle": "Section 10.1", "enabled": false},
	{"id": "math.u10.functions-graphs.linear", "title": "Graph of Linear Functions", "subtitle": "Section 10.1.1", "enabled": false},
	{"id": "math.u10.functions-graphs.quadratic", "title": "Graph of Quadratic Functions", "subtitle": "Section 10.1.2", "enabled": false},
	{"id": "math.u10.functions-graphs.cubic", "title": "Graph of Cubic Functions", "subtitle": "Section 10.1.3", "enabled": false},
	{"id": "math.u10.functions-graphs.reciprocal", "title": "Graph of Reciprocal Functions", "subtitle": "Section 10.1.4", "enabled": false},
	{"id": "math.u10.functions-graphs.exponential", "title": "Graph of Exponential Functions", "subtitle": "Section 10.1.5", "enabled": false},
	{"id": "math.u10.functions-graphs.power-functions", "title": "Graphs of y = a*x^n", "subtitle": "Section 10.1.6", "enabled": false},
	{"id": "math.u10.exponential-growth-decay", "title": "10.2 Exponential Growth/Decay of a Practical Phenomenon", "subtitle": "Section 10.2", "enabled": false},
	{"id": "math.u10.exponential-growth-decay.tangents", "title": "Gradients of Curves by Drawing Tangents", "subtitle": "Section 10.2.1", "enabled": false},
	{"id": "math.u10.exponential-growth-decay.real-life", "title": "Applications of Graph in Real-Life", "subtitle": "Section 10.2.2", "enabled": false},
	{"id": "math.u10.ex-10.1", "title": "Exercise 10.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u10.ex-10.2", "title": "Exercise 10.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u10.review", "title": "Review Exercise 10", "subtitle": "Unit review", "enabled": false},
]

const UNIT11_TOPICS := [
	{"id": "math.u11.construction-of-triangles", "title": "11.1 Construction of Triangles", "subtitle": "Section 11.1", "enabled": false},
	{"id": "math.u11.perpendicular-bisectors-medians", "title": "11.2 Perpendicular Bisectors and Medians of a Triangle", "subtitle": "Section 11.2", "enabled": false},
	{"id": "math.u11.angle-bisector", "title": "11.3 Angle Bisector of a Triangle", "subtitle": "Section 11.3", "enabled": false},
	{"id": "math.u11.altitudes", "title": "11.4 Altitudes of Triangle", "subtitle": "Section 11.4", "enabled": false},
	{"id": "math.u11.loci-construction", "title": "11.5 Loci and Construction", "subtitle": "Section 11.5", "enabled": false},
	{"id": "math.u11.loci-construction.two-dimensions", "title": "Loci in Two Dimensions", "subtitle": "Section 11.5.1", "enabled": false},
	{"id": "math.u11.loci-construction.intersection", "title": "Intersection of Loci", "subtitle": "Section 11.5.2", "enabled": false},
	{"id": "math.u11.ex-11.2", "title": "Exercise 11.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u11.review", "title": "Review Exercise 11", "subtitle": "Unit review", "enabled": false},
]

const UNIT12_TOPICS := [
	{"id": "math.u12.ungrouped-grouped-data", "title": "12.1 Ungrouped and Grouped Data", "subtitle": "Section 12.1", "enabled": false},
	{"id": "math.u12.ungrouped-grouped-data.frequency-distribution", "title": "Frequency Distribution", "subtitle": "Section 12.1.1", "enabled": false},
	{"id": "math.u12.ungrouped-grouped-data.frequency-graph", "title": "Graph of Frequency Distribution", "subtitle": "Section 12.1.2", "enabled": false},
	{"id": "math.u12.ungrouped-grouped-data.histogram", "title": "Histogram (with unequal class limits)", "subtitle": "Section 12.1.3", "enabled": false},
	{"id": "math.u12.ungrouped-grouped-data.frequency-polygon", "title": "Frequency Polygon", "subtitle": "Section 12.1.4", "enabled": false},
	{"id": "math.u12.measures-location", "title": "12.2 Measures of Location (Central Tendency)", "subtitle": "Section 12.2", "enabled": false},
	{"id": "math.u12.measures-location.arithmetic-mean", "title": "Arithmetic Mean (A.M.)", "subtitle": "Section 12.2.1", "enabled": false},
	{"id": "math.u12.measures-location.median", "title": "Median", "subtitle": "Section 12.2.2", "enabled": false},
	{"id": "math.u12.measures-location.mode", "title": "Mode", "subtitle": "Section 12.2.3", "enabled": false},
	{"id": "math.u12.measures-location.weighted-mean", "title": "Weighted Mean", "subtitle": "Section 12.2.4", "enabled": false},
	{"id": "math.u12.measures-location.real-life", "title": "Real Life Situations Involving Mean, Weighted Mean, Median and Mode", "subtitle": "Section 12.2.5", "enabled": false},
	{"id": "math.u12.ex-12.2", "title": "Exercise 12.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u12.review", "title": "Review Exercise 12", "subtitle": "Unit review", "enabled": false},
]

const UNIT13_TOPICS := [
	{"id": "math.u13.probability-single-event", "title": "13.1 Probability of Single Event", "subtitle": "Section 13.1", "enabled": false},
	{"id": "math.u13.event-not-occurring", "title": "13.2 Probability of an Event Not Occurring", "subtitle": "Section 13.2", "enabled": false},
	{"id": "math.u13.probability-real-life-problems", "title": "13.3 Real Life Problems Involving Probability", "subtitle": "Section 13.3", "enabled": false},
	{"id": "math.u13.relative-frequency", "title": "13.4 Relative Frequency as an Estimate of Probability", "subtitle": "Section 13.4", "enabled": false},
	{"id": "math.u13.relative-frequency.real-life", "title": "Real Life Application of Relative Frequency", "subtitle": "Section 13.5", "enabled": false},
	{"id": "math.u13.expected-frequency", "title": "13.6 Expected Frequency", "subtitle": "Section 13.6", "enabled": false},
	{"id": "math.u13.expected-frequency.real-life", "title": "Real Life Application on Expected Frequency", "subtitle": "Section 13.7", "enabled": false},
	{"id": "math.u13.ex-13.1", "title": "Exercise 13.1", "subtitle": "Practice", "enabled": false},
	{"id": "math.u13.ex-13.2", "title": "Exercise 13.2", "subtitle": "Practice", "enabled": false},
	{"id": "math.u13.review", "title": "Review Exercise 13", "subtitle": "Unit review", "enabled": false},
]

# Computer Science and Entrepreneurship-9 (PCTB, exact book order).
# Unit list mirrors MATH_CHAPTERS for the chapters grid.
const CS_UNITS := [
	{"id": "cs.u01", "title": "Unit 1", "subtitle": "Introduction to Systems", "enabled": true},
	{"id": "cs.u02", "title": "Unit 2", "subtitle": "Number Systems", "enabled": true},
	{"id": "cs.u03", "title": "Unit 3", "subtitle": "Digital Systems and Logic Design", "enabled": true},
	{"id": "cs.u04", "title": "Unit 4", "subtitle": "System Troubleshooting", "enabled": true},
	{"id": "cs.u05", "title": "Unit 5", "subtitle": "Software System", "enabled": true},
	{"id": "cs.u06", "title": "Unit 6", "subtitle": "Introduction to Computer Networks", "enabled": true},
	{"id": "cs.u07", "title": "Unit 7", "subtitle": "Computational Thinking", "enabled": true},
	{"id": "cs.u08", "title": "Unit 8", "subtitle": "Web Development with HTML, CSS and JavaScript", "enabled": true},
	{"id": "cs.u09", "title": "Unit 9", "subtitle": "Data Science and Data Gathering", "enabled": true},
	{"id": "cs.u10", "title": "Unit 10", "subtitle": "Emerging Technologies in Computer Science", "enabled": true},
	{"id": "cs.u11", "title": "Unit 11", "subtitle": "Ethical, Social, and Legal Concerns in Computer Usage", "enabled": true},
	{"id": "cs.u12", "title": "Unit 12", "subtitle": "Entrepreneurship in Digital Age", "enabled": true},
]

const CS_UNIT1_TOPICS := [
	{"id": "cs.u01.theory-of-systems", "title": "1.1 Theory of Systems", "subtitle": "Section 1.1", "enabled": false},
	{"id": "cs.u01.theory-of-systems.basic-concepts", "title": "Basic Concepts of Systems", "subtitle": "Section 1.1.1", "enabled": false},
	{"id": "cs.u01.theory-of-systems.basic-concepts.objective", "title": "Objective", "subtitle": "Section 1.1.1.1", "enabled": false},
	{"id": "cs.u01.theory-of-systems.basic-concepts.components", "title": "Components", "subtitle": "Section 1.1.1.2", "enabled": false},
	{"id": "cs.u01.theory-of-systems.basic-concepts.environment", "title": "Environment", "subtitle": "Section 1.1.1.3", "enabled": false},
	{"id": "cs.u01.theory-of-systems.basic-concepts.communication", "title": "Communication", "subtitle": "Section 1.1.1.4", "enabled": false},
	{"id": "cs.u01.types-of-systems", "title": "1.2 Types of Systems", "subtitle": "Section 1.2", "enabled": false},
	{"id": "cs.u01.types-of-systems.natural-systems", "title": "Natural Systems", "subtitle": "Section 1.2.1", "enabled": false},
	{"id": "cs.u01.types-of-systems.natural-systems.physical", "title": "Physical Systems", "subtitle": "Section 1.2.1.1", "enabled": false},
	{"id": "cs.u01.types-of-systems.natural-systems.chemical", "title": "Chemical Systems", "subtitle": "Section 1.2.1.2", "enabled": false},
	{"id": "cs.u01.types-of-systems.natural-systems.biological", "title": "Biological Systems", "subtitle": "Section 1.2.1.3", "enabled": false},
	{"id": "cs.u01.types-of-systems.natural-systems.psychological", "title": "Psychological Systems", "subtitle": "Section 1.2.1.4", "enabled": false},
	{"id": "cs.u01.types-of-systems.artificial-systems", "title": "Artificial Systems", "subtitle": "Section 1.2.2", "enabled": false},
	{"id": "cs.u01.types-of-systems.artificial-systems.knowledge", "title": "Knowledge Systems", "subtitle": "Section 1.2.2.1", "enabled": false},
	{"id": "cs.u01.types-of-systems.artificial-systems.engineering", "title": "Engineering Systems", "subtitle": "Section 1.2.2.2", "enabled": false},
	{"id": "cs.u01.types-of-systems.artificial-systems.social", "title": "Social Systems", "subtitle": "Section 1.2.2.3", "enabled": false},
	{"id": "cs.u01.system-and-science", "title": "1.3 System and Science", "subtitle": "Section 1.3", "enabled": false},
	{"id": "cs.u01.system-and-science.natural-science", "title": "Natural Science", "subtitle": "Section 1.3.1", "enabled": false},
	{"id": "cs.u01.system-and-science.design-science", "title": "Design Science", "subtitle": "Section 1.3.2", "enabled": false},
	{"id": "cs.u01.system-and-science.computer-science", "title": "Computer Science", "subtitle": "Section 1.3.3", "enabled": false},
	{"id": "cs.u01.system-and-science.computer-science.natural", "title": "Natural Science of Computer Science", "subtitle": "Section 1.3.3.1", "enabled": false},
	{"id": "cs.u01.system-and-science.computer-science.design", "title": "Design Science of Computer Science", "subtitle": "Section 1.3.3.2", "enabled": false},
	{"id": "cs.u01.computer-as-a-system", "title": "1.4 Computer as a System", "subtitle": "Section 1.4", "enabled": false},
	{"id": "cs.u01.computer-as-a-system.objective", "title": "Objective", "subtitle": "Section 1.4.1", "enabled": false},
	{"id": "cs.u01.computer-as-a-system.components", "title": "Components", "subtitle": "Section 1.4.2", "enabled": false},
	{"id": "cs.u01.computer-as-a-system.interactions", "title": "Interactions among Components", "subtitle": "Section 1.4.3", "enabled": false},
	{"id": "cs.u01.computer-as-a-system.environment", "title": "Environment", "subtitle": "Section 1.4.4", "enabled": false},
	{"id": "cs.u01.computer-as-a-system.interaction-environment", "title": "Interaction with the Environment", "subtitle": "Section 1.4.5", "enabled": false},
	{"id": "cs.u01.von-neumann-architecture", "title": "1.5 The Architecture of von Neumann Computers", "subtitle": "Section 1.5", "enabled": false},
	{"id": "cs.u01.von-neumann-architecture.components", "title": "Components", "subtitle": "Section 1.5.1", "enabled": false},
	{"id": "cs.u01.von-neumann-architecture.working", "title": "Working", "subtitle": "Section 1.5.2", "enabled": false},
	{"id": "cs.u01.von-neumann-architecture.characteristics", "title": "Characteristics", "subtitle": "Section 1.5.3", "enabled": false},
	{"id": "cs.u01.von-neumann-architecture.advantages-disadvantages", "title": "Advantages and Disadvantages", "subtitle": "Section 1.5.4", "enabled": false},
	{"id": "cs.u01.computing-systems", "title": "1.6 Computing Systems", "subtitle": "Section 1.6", "enabled": false},
	{"id": "cs.u01.computing-systems.types", "title": "Types of Computing Systems", "subtitle": "Section 1.6.1", "enabled": false},
	{"id": "cs.u01.computing-systems.network-as-system", "title": "Computer Network as Systems", "subtitle": "Section 1.6.2", "enabled": false},
	{"id": "cs.u01.computing-systems.network-as-system.objectives", "title": "Objectives", "subtitle": "Section 1.6.2.1", "enabled": false},
	{"id": "cs.u01.computing-systems.network-as-system.components", "title": "Components", "subtitle": "Section 1.6.2.2", "enabled": false},
	{"id": "cs.u01.computing-systems.network-as-system.environment", "title": "Environment", "subtitle": "Section 1.6.2.3", "enabled": false},
	{"id": "cs.u01.computing-systems.network-as-system.types", "title": "Types of Computer Networks", "subtitle": "Section 1.6.2.4", "enabled": false},
	{"id": "cs.u01.computing-systems.internet-as-system", "title": "Internet as a System", "subtitle": "Section 1.6.3", "enabled": false},
	{"id": "cs.u01.computing-systems.internet-as-system.protocols", "title": "Internet Protocols", "subtitle": "Section 1.6.3.1", "enabled": false},
	{"id": "cs.u01.computing-systems.internet-as-system.interactions", "title": "Interaction among Components", "subtitle": "Section 1.6.3.2", "enabled": false},
	{"id": "cs.u01.computing-systems.internet-as-system.environment", "title": "Environment", "subtitle": "Section 1.6.3.3", "enabled": false},
	{"id": "cs.u01.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u01.mcqs", "title": "Multiple Choice Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u01.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u01.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT2_TOPICS := [
	{"id": "cs.u02.numbering-systems", "title": "2.1 Numbering Systems", "subtitle": "Section 2.1", "enabled": false},
	{"id": "cs.u02.numbering-systems.decimal", "title": "Decimal System", "subtitle": "Section 2.1.1", "enabled": false},
	{"id": "cs.u02.numbering-systems.binary", "title": "Binary System", "subtitle": "Section 2.1.2", "enabled": false},
	{"id": "cs.u02.numbering-systems.binary.decimal-to-binary", "title": "Conversion from Decimal to Binary", "subtitle": "Section 2.1.2.1", "enabled": false},
	{"id": "cs.u02.numbering-systems.octal", "title": "Octal System", "subtitle": "Section 2.1.3", "enabled": false},
	{"id": "cs.u02.numbering-systems.octal.decimal-to-octal", "title": "Conversion from Decimal to Octal", "subtitle": "Section 2.1.3.1", "enabled": false},
	{"id": "cs.u02.numbering-systems.hexadecimal", "title": "Hexadecimal System", "subtitle": "Section 2.1.4", "enabled": false},
	{"id": "cs.u02.numbering-systems.hexadecimal.decimal-to-hex", "title": "Converting Decimal to Hexadecimal", "subtitle": "Section 2.1.4.1", "enabled": false},
	{"id": "cs.u02.data-representation", "title": "2.2 Data Representation in Computing Systems", "subtitle": "Section 2.2", "enabled": false},
	{"id": "cs.u02.data-representation.binary-encoding", "title": "Binary Encoding of Integers (Z) and Real Numbers (R)", "subtitle": "Section 2.2.1", "enabled": false},
	{"id": "cs.u02.data-representation.whole-and-integers", "title": "Whole Numbers (W) and Integers (Z)", "subtitle": "Section 2.2.2", "enabled": false},
	{"id": "cs.u02.data-representation.whole-and-integers.whole", "title": "Whole Numbers (W)", "subtitle": "Section 2.2.2.1", "enabled": false},
	{"id": "cs.u02.data-representation.whole-and-integers.integers", "title": "Integers (Z)", "subtitle": "Section 2.2.2.2", "enabled": false},
	{"id": "cs.u02.data-representation.whole-and-integers.twos-complement", "title": "Negative Values and Two's Complement", "subtitle": "Section 2.2.2.3", "enabled": false},
	{"id": "cs.u02.storing-real-values", "title": "2.3 Storing Real Values in Computer Memory", "subtitle": "Section 2.3", "enabled": false},
	{"id": "cs.u02.storing-real-values.floating-point", "title": "Understanding Floating-Point Representation", "subtitle": "Section 2.3.1", "enabled": false},
	{"id": "cs.u02.storing-real-values.floating-point.single-precision", "title": "Single Precision (32-bit)", "subtitle": "Section 2.3.1.1", "enabled": false},
	{"id": "cs.u02.storing-real-values.floating-point.double-precision", "title": "Double Precision (64-bit)", "subtitle": "Section 2.3.1.2", "enabled": false},
	{"id": "cs.u02.binary-arithmetic", "title": "2.4 Binary Arithmetic Operations", "subtitle": "Section 2.4", "enabled": false},
	{"id": "cs.u02.binary-arithmetic.addition", "title": "Addition", "subtitle": "Section 2.4.1", "enabled": false},
	{"id": "cs.u02.binary-arithmetic.subtraction", "title": "Subtraction", "subtitle": "Section 2.4.2", "enabled": false},
	{"id": "cs.u02.binary-arithmetic.multiplication", "title": "Multiplication", "subtitle": "Section 2.4.3", "enabled": false},
	{"id": "cs.u02.binary-arithmetic.division", "title": "Division", "subtitle": "Section 2.4.4", "enabled": false},
	{"id": "cs.u02.text-encoding", "title": "2.5 Common Text Encoding Schemes", "subtitle": "Section 2.5", "enabled": false},
	{"id": "cs.u02.text-encoding.ascii", "title": "ASCII", "subtitle": "Section 2.5.1 (first)", "enabled": false},
	{"id": "cs.u02.text-encoding.extended-ascii", "title": "Extended ASCII", "subtitle": "Section 2.5.1 (second)", "enabled": false},
	{"id": "cs.u02.text-encoding.unicode", "title": "Unicode", "subtitle": "Section 2.5.2", "enabled": false},
	{"id": "cs.u02.text-encoding.unicode.utf-8", "title": "UTF-8", "subtitle": "Section 2.5.2.1", "enabled": false},
	{"id": "cs.u02.text-encoding.unicode.utf-16", "title": "UTF-16", "subtitle": "Section 2.5.2.2", "enabled": false},
	{"id": "cs.u02.text-encoding.unicode.utf-32", "title": "UTF-32", "subtitle": "Section 2.5.2.3", "enabled": false},
	{"id": "cs.u02.storing-media", "title": "2.6 Storing Images, Audio, and Video in Computers", "subtitle": "Section 2.6", "enabled": false},
	{"id": "cs.u02.storing-media.images", "title": "Storing Images", "subtitle": "Section 2.6.1", "enabled": false},
	{"id": "cs.u02.storing-media.audio", "title": "Storing Audio", "subtitle": "Section 2.6.2", "enabled": false},
	{"id": "cs.u02.storing-media.video", "title": "Storing Video", "subtitle": "Section 2.6.3", "enabled": false},
	{"id": "cs.u02.storing-media.file-storage", "title": "How Computers Store These Files", "subtitle": "Section 2.6.4", "enabled": false},
	{"id": "cs.u02.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u02.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u02.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT3_TOPICS := [
	{"id": "cs.u03.basics-of-digital-systems", "title": "3.1 Basics of Digital Systems", "subtitle": "Section 3.1", "enabled": false},
	{"id": "cs.u03.basics-of-digital-systems.analog-signal", "title": "What is an Analog Signal", "subtitle": "Section 3.1.1", "enabled": false},
	{"id": "cs.u03.basics-of-digital-systems.digital-logic", "title": "Fundamentals of Digital Logic", "subtitle": "Section 3.1.2", "enabled": false},
	{"id": "cs.u03.boolean-algebra-logic-gates", "title": "3.2 Boolean Algebra and Logic Gates", "subtitle": "Section 3.2", "enabled": false},
	{"id": "cs.u03.boolean-algebra-logic-gates.functions-expressions", "title": "Boolean Functions and Expressions", "subtitle": "Section 3.2.1", "enabled": false},
	{"id": "cs.u03.boolean-algebra-logic-gates.functions-expressions.variables-operations", "title": "Binary Variables and Logic Operations", "subtitle": "Section 3.2.1.1", "enabled": false},
	{"id": "cs.u03.boolean-algebra-logic-gates.functions-expressions.construction", "title": "Construction of Boolean Functions", "subtitle": "Section 3.2.1.2", "enabled": false},
	{"id": "cs.u03.boolean-algebra-logic-gates.gates", "title": "Logic Gates and their Functions", "subtitle": "Section 3.2.2", "enabled": false},
	{"id": "cs.u03.simplification", "title": "3.3 Simplification of Boolean Functions", "subtitle": "Section 3.3", "enabled": false},
	{"id": "cs.u03.logic-diagrams", "title": "3.4 Creating Logic Diagrams", "subtitle": "Section 3.4", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic", "title": "3.5 Application of Digital Logic", "subtitle": "Section 3.5", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.adder-circuits", "title": "Half-adder and Full-adder Circuits", "subtitle": "Section 3.5.1", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.adder-circuits.half-adder", "title": "Half-adder Circuits", "subtitle": "Section 3.5.1.1", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.adder-circuits.full-adder", "title": "Full-adder Circuits", "subtitle": "Section 3.5.1.2", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.karnaugh-map", "title": "Karnaugh Map (K-Map)", "subtitle": "Section 3.5.2", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.karnaugh-map.structure", "title": "Structure of Karnaugh Maps", "subtitle": "Section 3.5.2.1", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.karnaugh-map.minterms", "title": "Minterms in Boolean Algebra", "subtitle": "Section 3.5.2.2", "enabled": false},
	{"id": "cs.u03.application-of-digital-logic.karnaugh-map.creating", "title": "Creating Karnaugh Maps", "subtitle": "Section 3.5.2.3", "enabled": false},
	{"id": "cs.u03.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u03.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u03.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u03.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT4_TOPICS := [
	{"id": "cs.u04.system-troubleshooting", "title": "4.1 System Troubleshooting", "subtitle": "Section 4.1", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process", "title": "Systematic Process of Troubleshooting", "subtitle": "Section 4.1.1", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.identify-problem", "title": "Identify Problem", "subtitle": "Section 4.1.1.1", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.theory-of-cause", "title": "Establish a Theory of Probable Cause", "subtitle": "Section 4.1.1.2", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.test-theory", "title": "Test the Theory to Determine the Cause", "subtitle": "Section 4.1.1.3", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.plan-of-action", "title": "Establish a Plan of Action to Resolve the Problem", "subtitle": "Section 4.1.1.4", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.implement-solution", "title": "Implement the Solution", "subtitle": "Section 4.1.1.5", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.verify-functionality", "title": "Verify Full System Functionality", "subtitle": "Section 4.1.1.6", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.systematic-process.document-findings", "title": "Document Findings, Actions, and Outcomes", "subtitle": "Section 4.1.1.7", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance", "title": "Importance of Troubleshooting in Computing Systems", "subtitle": "Section 4.1.2", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.preventing-downtime", "title": "Preventing Downtime", "subtitle": "Section 4.1.2.1", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.data-integrity", "title": "Ensuring Data Integrity", "subtitle": "Section 4.1.2.2", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.improving-security", "title": "Improving Security", "subtitle": "Section 4.1.2.3", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.enhancing-performance", "title": "Enhancing Performance", "subtitle": "Section 4.1.2.4", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.equipment-life", "title": "Extending Equipment Life", "subtitle": "Section 4.1.2.5", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.saving-costs", "title": "Saving Costs", "subtitle": "Section 4.1.2.6", "enabled": false},
	{"id": "cs.u04.system-troubleshooting.importance.user-experience", "title": "Enhancing User Experience", "subtitle": "Section 4.1.2.7", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies", "title": "4.2 Troubleshooting Strategies", "subtitle": "Section 4.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.software-issues", "title": "Basic Software-Related Issues", "subtitle": "Section 4.2.1", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.software-issues.common-issues", "title": "Common Software Issues and Solutions", "subtitle": "Section 4.2.1.1", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.software-issues.restart-shutdown", "title": "Restarting and Shutting Down", "subtitle": "Section 4.2.1.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.hardware-issues", "title": "Basic Hardware-Related Issues", "subtitle": "Section 4.2.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.hardware-issues.common-issues", "title": "Common Hardware Issues and Solutions", "subtitle": "Section 4.2.2.1", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.hardware-issues.safe-workspace", "title": "Maintaining a Safe Workspace", "subtitle": "Section 4.2.2.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.diagnosis-maintenance", "title": "Hardware Diagnosis and Maintenance", "subtitle": "Section 4.2.3", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.diagnosis-maintenance.failures", "title": "Recognizing Hardware Failures", "subtitle": "Section 4.2.3.1", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.diagnosis-maintenance.replacements", "title": "Component Replacements and Upgrades", "subtitle": "Section 4.2.3.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.security-maintenance", "title": "Security and Maintenance", "subtitle": "Section 4.2.4", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.security-maintenance.software", "title": "Maintaining Software", "subtitle": "Section 4.2.4.1", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.security-maintenance.threats", "title": "Addressing Security Threats", "subtitle": "Section 4.2.4.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.data-management", "title": "Data Management and Backups", "subtitle": "Section 4.2.5", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.data-management.storage-space", "title": "Managing Storage Space", "subtitle": "Section 4.2.5.1", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.data-management.backup-methods", "title": "Data Backup Methods", "subtitle": "Section 4.2.5.2", "enabled": false},
	{"id": "cs.u04.troubleshooting-strategies.resources", "title": "Using Resources for Troubleshooting", "subtitle": "Section 4.2.6", "enabled": false},
	{"id": "cs.u04.assisting-others", "title": "4.3 Assisting Others", "subtitle": "Section 4.3", "enabled": false},
	{"id": "cs.u04.assisting-others.communication-collaboration", "title": "Communication and Collaboration", "subtitle": "Section 4.3.1", "enabled": false},
	{"id": "cs.u04.assisting-others.sharing-knowledge", "title": "Sharing Troubleshooting Knowledge", "subtitle": "Section 4.3.2", "enabled": false},
	{"id": "cs.u04.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u04.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u04.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u04.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT5_TOPICS := [
	{"id": "cs.u05.software", "title": "5.1 Software", "subtitle": "Section 5.1", "enabled": false},
	{"id": "cs.u05.software.types", "title": "Types of Software", "subtitle": "Section 5.1.2", "enabled": false},
	{"id": "cs.u05.software.types.system", "title": "System Software", "subtitle": "Section 5.1.2.1", "enabled": false},
	{"id": "cs.u05.software.types.application", "title": "Application Software", "subtitle": "Section 5.1.2.2", "enabled": false},
	{"id": "cs.u05.software.types.differentiating", "title": "Differentiating Between System Software and Application Software", "subtitle": "Section 5.1.2.3", "enabled": false},
	{"id": "cs.u05.system-software", "title": "5.2 Introduction to System Software", "subtitle": "Section 5.2", "enabled": false},
	{"id": "cs.u05.system-software.operating-system", "title": "Operating System", "subtitle": "Section 5.2.1", "enabled": false},
	{"id": "cs.u05.system-software.operating-system.hardware-resources", "title": "Managing Hardware Resources", "subtitle": "Section 5.2.1.1", "enabled": false},
	{"id": "cs.u05.system-software.operating-system.user-interface", "title": "Providing a User Interface", "subtitle": "Section 5.2.1.2", "enabled": false},
	{"id": "cs.u05.system-software.operating-system.running-applications", "title": "Running Applications", "subtitle": "Section 5.2.1.3", "enabled": false},
	{"id": "cs.u05.system-software.utility-programs", "title": "Utility Programs", "subtitle": "Section 5.2.2", "enabled": false},
	{"id": "cs.u05.system-software.utility-programs.disk-cleanup", "title": "Disk Cleanup", "subtitle": "Section 5.2.2.1", "enabled": false},
	{"id": "cs.u05.system-software.utility-programs.antivirus", "title": "Antivirus Software", "subtitle": "Section 5.2.2.2", "enabled": false},
	{"id": "cs.u05.system-software.utility-programs.backup", "title": "Backup Software", "subtitle": "Section 5.2.2.3", "enabled": false},
	{"id": "cs.u05.system-software.utility-programs.compression", "title": "File Compression Tools", "subtitle": "Section 5.2.2.4", "enabled": false},
	{"id": "cs.u05.system-software.device-drivers", "title": "Device Drivers", "subtitle": "Section 5.2.3", "enabled": false},
	{"id": "cs.u05.application-software", "title": "5.3 Application Software", "subtitle": "Section 5.3", "enabled": false},
	{"id": "cs.u05.application-software.commonly-used", "title": "Commonly used application software", "subtitle": "Section 5.3.1", "enabled": false},
	{"id": "cs.u05.application-software.commonly-used.word-processing", "title": "Word Processing Software", "subtitle": "Section 5.3.1.1", "enabled": false},
	{"id": "cs.u05.application-software.commonly-used.spreadsheet", "title": "Spreadsheet Software", "subtitle": "Section 5.3.1.2", "enabled": false},
	{"id": "cs.u05.application-software.commonly-used.graphic-design", "title": "Graphic Design Software", "subtitle": "Section 5.3.1.3", "enabled": false},
	{"id": "cs.u05.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u05.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u05.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u05.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT6_TOPICS := [
	{"id": "cs.u06.network-as-a-system", "title": "6.1 Network as a System", "subtitle": "Section 6.1", "enabled": false},
	{"id": "cs.u06.network-as-a-system.objectives", "title": "Objectives of Computer Networks", "subtitle": "Section 6.1.1", "enabled": false},
	{"id": "cs.u06.data-communication", "title": "6.2 Fundamental Concepts in Data Communication", "subtitle": "Section 6.2", "enabled": false},
	{"id": "cs.u06.data-communication.components", "title": "Components of Data Communication", "subtitle": "Section 6.2.1", "enabled": false},
	{"id": "cs.u06.networking-devices", "title": "6.3 Networking Devices", "subtitle": "Section 6.3", "enabled": false},
	{"id": "cs.u06.networking-devices.switch", "title": "Switch", "subtitle": "Section 6.3.1", "enabled": false},
	{"id": "cs.u06.networking-devices.router", "title": "Router", "subtitle": "Section 6.3.2", "enabled": false},
	{"id": "cs.u06.networking-devices.access-point", "title": "Access Point", "subtitle": "Section 6.3.3", "enabled": false},
	{"id": "cs.u06.network-topologies", "title": "6.4 Network Topologies", "subtitle": "Section 6.4", "enabled": false},
	{"id": "cs.u06.network-topologies.bus", "title": "Bus Topology", "subtitle": "Section 6.4.1", "enabled": false},
	{"id": "cs.u06.network-topologies.star", "title": "Star Topology", "subtitle": "Section 6.4.2", "enabled": false},
	{"id": "cs.u06.network-topologies.ring", "title": "Ring Topology", "subtitle": "Section 6.4.3", "enabled": false},
	{"id": "cs.u06.transmission-modes", "title": "6.5 Transmission Modes", "subtitle": "Section 6.5", "enabled": false},
	{"id": "cs.u06.transmission-modes.simplex", "title": "Simplex Communication", "subtitle": "Section 6.5.1", "enabled": false},
	{"id": "cs.u06.transmission-modes.half-duplex", "title": "Half-Duplex Communication", "subtitle": "Section 6.5.2", "enabled": false},
	{"id": "cs.u06.transmission-modes.full-duplex", "title": "Full-Duplex Communication", "subtitle": "Section 6.5.3", "enabled": false},
	{"id": "cs.u06.osi-model", "title": "6.6 The OSI Networking Model", "subtitle": "Section 6.6", "enabled": false},
	{"id": "cs.u06.ipv4-ipv6", "title": "6.7 IPv4 and IPv6", "subtitle": "Section 6.7", "enabled": false},
	{"id": "cs.u06.ipv4-ipv6.ipv4", "title": "Internet Protocol version 4 (IPv4)", "subtitle": "Section 6.7.1", "enabled": false},
	{"id": "cs.u06.ipv4-ipv6.ipv6", "title": "Internet Protocol version 6 (IPv6)", "subtitle": "Section 6.7.2", "enabled": false},
	{"id": "cs.u06.protocols-network-services", "title": "6.8 Protocols and Network Services", "subtitle": "Section 6.8", "enabled": false},
	{"id": "cs.u06.protocols-network-services.introduction", "title": "Introduction to Protocols", "subtitle": "Section 6.8.1", "enabled": false},
	{"id": "cs.u06.protocols-network-services.dns-dhcp", "title": "DNS and DHCP", "subtitle": "Section 6.8.2", "enabled": false},
	{"id": "cs.u06.network-security", "title": "6.9 Network Security", "subtitle": "Section 6.9", "enabled": false},
	{"id": "cs.u06.network-security.importance", "title": "Importance of Network Security", "subtitle": "Section 6.9.1", "enabled": false},
	{"id": "cs.u06.network-security.key-concepts", "title": "Key Concepts in Network Security", "subtitle": "Section 6.9.2", "enabled": false},
	{"id": "cs.u06.network-security.threats", "title": "Common Threats to Network Security", "subtitle": "Section 6.9.3", "enabled": false},
	{"id": "cs.u06.types-of-networks", "title": "6.10 Types of Networks", "subtitle": "Section 6.10", "enabled": false},
	{"id": "cs.u06.types-of-networks.pan", "title": "Personal Area Network (PAN)", "subtitle": "Section 6.10.1", "enabled": false},
	{"id": "cs.u06.types-of-networks.man", "title": "Metropolitan Area Network (MAN)", "subtitle": "Section 6.10.2", "enabled": false},
	{"id": "cs.u06.types-of-networks.wan", "title": "Wide Area Network (WAN)", "subtitle": "Section 6.10.3", "enabled": false},
	{"id": "cs.u06.types-of-networks.can", "title": "Campus Area Network (CAN)", "subtitle": "Section 6.10.4", "enabled": false},
	{"id": "cs.u06.real-world-applications", "title": "6.11 Real-World Applications of Computer Networks", "subtitle": "Section 6.11", "enabled": false},
	{"id": "cs.u06.real-world-applications.business", "title": "Business", "subtitle": "Section 6.11.1", "enabled": false},
	{"id": "cs.u06.real-world-applications.education", "title": "Education", "subtitle": "Section 6.11.2", "enabled": false},
	{"id": "cs.u06.real-world-applications.healthcare", "title": "Healthcare", "subtitle": "Section 6.11.3", "enabled": false},
	{"id": "cs.u06.tcp-ip", "title": "6.12 Standard Protocols in TCP/IP Communications", "subtitle": "Section 6.12", "enabled": false},
	{"id": "cs.u06.tcp-ip.introduction", "title": "Introduction to TCP/IP", "subtitle": "Section 6.12.1", "enabled": false},
	{"id": "cs.u06.tcp-ip.key-protocols", "title": "Key Protocols", "subtitle": "Section 6.12.2", "enabled": false},
	{"id": "cs.u06.network-security-methods", "title": "6.13 Network Security Methods", "subtitle": "Section 6.13", "enabled": false},
	{"id": "cs.u06.network-security-methods.firewalls", "title": "Firewalls", "subtitle": "Section 6.13.1", "enabled": false},
	{"id": "cs.u06.network-security-methods.encryption", "title": "Encryption", "subtitle": "Section 6.13.2", "enabled": false},
	{"id": "cs.u06.network-security-methods.antivirus", "title": "Antivirus Software", "subtitle": "Section 6.13.3", "enabled": false},
	{"id": "cs.u06.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u06.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u06.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u06.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT7_TOPICS := [
	{"id": "cs.u07.definition", "title": "7.1 Definition of Computational Thinking", "subtitle": "Section 7.1", "enabled": false},
	{"id": "cs.u07.definition.decomposition", "title": "Decomposition", "subtitle": "Section 7.1.1", "enabled": false},
	{"id": "cs.u07.definition.pattern-recognition", "title": "Pattern Recognition", "subtitle": "Section 7.1.2", "enabled": false},
	{"id": "cs.u07.definition.abstraction", "title": "Abstraction", "subtitle": "Section 7.1.3", "enabled": false},
	{"id": "cs.u07.definition.algorithms", "title": "Algorithms", "subtitle": "Section 7.1.4", "enabled": false},
	{"id": "cs.u07.principles", "title": "7.2 Principles of Computational Thinking", "subtitle": "Section 7.2", "enabled": false},
	{"id": "cs.u07.principles.problem-understanding", "title": "Problem Understanding", "subtitle": "Section 7.2.1", "enabled": false},
	{"id": "cs.u07.principles.problem-simplification", "title": "Problem Simplification", "subtitle": "Section 7.2.2", "enabled": false},
	{"id": "cs.u07.principles.solution-selection-design", "title": "Solution Selection and Design", "subtitle": "Section 7.2.3", "enabled": false},
	{"id": "cs.u07.algorithm-design-methods", "title": "7.3 Algorithm Design Methods", "subtitle": "Section 7.3", "enabled": false},
	{"id": "cs.u07.algorithm-design-methods.flowcharts", "title": "Flowcharts", "subtitle": "Section 7.3.1", "enabled": false},
	{"id": "cs.u07.algorithm-design-methods.flowcharts.importance", "title": "Importance of Flowcharts", "subtitle": "Section 7.3.1.1", "enabled": false},
	{"id": "cs.u07.algorithm-design-methods.flowcharts.symbols", "title": "Flowchart Symbols", "subtitle": "Section 7.3.1.2", "enabled": false},
	{"id": "cs.u07.algorithm-design-methods.pseudocode", "title": "Pseudocode", "subtitle": "Section 7.3.2", "enabled": false},
	{"id": "cs.u07.algorithm-design-methods.differentiating", "title": "Differentiating Flowcharts and Pseudocode", "subtitle": "Section 7.3.3", "enabled": false},
	{"id": "cs.u07.algorithmic-activities", "title": "7.4 Algorithmic Activities", "subtitle": "Section 7.4", "enabled": false},
	{"id": "cs.u07.algorithmic-activities.design-evaluation", "title": "Design and Evaluation Techniques", "subtitle": "Section 7.4.1", "enabled": false},
	{"id": "cs.u07.algorithmic-activities.design-evaluation.time-complexity", "title": "Time Complexity", "subtitle": "Section 7.4.1.1", "enabled": false},
	{"id": "cs.u07.algorithmic-activities.design-evaluation.space-complexity", "title": "Space Complexity", "subtitle": "Section 7.4.1.2", "enabled": false},
	{"id": "cs.u07.dry-run", "title": "7.5 Dry Run", "subtitle": "Section 7.5", "enabled": false},
	{"id": "cs.u07.dry-run.flowchart", "title": "Dry Run of a Flowchart", "subtitle": "Section 7.5.1", "enabled": false},
	{"id": "cs.u07.dry-run.pseudocode", "title": "Dry Run of Pseudocode", "subtitle": "Section 7.5.2", "enabled": false},
	{"id": "cs.u07.dry-run.simulation", "title": "Simulation", "subtitle": "Section 7.5.3", "enabled": false},
	{"id": "cs.u07.larp", "title": "7.6 Introduction to LARP (Logic of Algorithms for Resolution of Problems)", "subtitle": "Section 7.6", "enabled": false},
	{"id": "cs.u07.larp.importance", "title": "Why is LARP Important?", "subtitle": "Section 7.6.1", "enabled": false},
	{"id": "cs.u07.larp.writing-algorithms", "title": "Writing Algorithms", "subtitle": "Section 7.6.2", "enabled": false},
	{"id": "cs.u07.larp.flowcharts", "title": "Drawing Flowcharts in LARP", "subtitle": "Section 7.6.3", "enabled": false},
	{"id": "cs.u07.error-identification-debugging", "title": "7.7 Error Identification and Debugging", "subtitle": "Section 7.7", "enabled": false},
	{"id": "cs.u07.error-identification-debugging.types-of-errors", "title": "Types of Errors", "subtitle": "Section 7.7.1", "enabled": false},
	{"id": "cs.u07.error-identification-debugging.debugging-techniques", "title": "Debugging Techniques", "subtitle": "Section 7.7.2", "enabled": false},
	{"id": "cs.u07.error-identification-debugging.error-messages", "title": "Common Error Messages in LARP", "subtitle": "Section 7.7.3", "enabled": false},
	{"id": "cs.u07.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u07.mcqs", "title": "Multiple Choice Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u07.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u07.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT8_TOPICS := [
	{"id": "cs.u08.web-development", "title": "8.1 Web Development", "subtitle": "Section 8.1", "enabled": false},
	{"id": "cs.u08.web-development.why-learn", "title": "Why Learn Web Development?", "subtitle": "Section 8.1.1", "enabled": false},
	{"id": "cs.u08.basic-components", "title": "8.2 Basic Components of Web Development", "subtitle": "Section 8.2", "enabled": false},
	{"id": "cs.u08.getting-started-html", "title": "8.3 Getting Started with HTML", "subtitle": "Section 8.3", "enabled": false},
	{"id": "cs.u08.getting-started-html.history", "title": "History of HTML", "subtitle": "Section 8.3.1", "enabled": false},
	{"id": "cs.u08.getting-started-html.dev-environment", "title": "Setting up a Development Environment", "subtitle": "Section 8.3.2", "enabled": false},
	{"id": "cs.u08.getting-started-html.hello-world", "title": "Creating a Hello, World! HTML Application", "subtitle": "Section 8.3.3", "enabled": false},
	{"id": "cs.u08.getting-started-html.hello-world.writing-code", "title": "Writing the HTML Code", "subtitle": "Section 8.3.3.1", "enabled": false},
	{"id": "cs.u08.getting-started-html.hello-world.viewing-file", "title": "Viewing the HTML File", "subtitle": "Section 8.3.3.2", "enabled": false},
	{"id": "cs.u08.html-basic-structure", "title": "8.4 HTML Basic Structure", "subtitle": "Section 8.4", "enabled": false},
	{"id": "cs.u08.html-basic-structure.tags", "title": "HTML Tags", "subtitle": "Section 8.4.1", "enabled": false},
	{"id": "cs.u08.creating-content", "title": "8.5 Creating Content with HTML", "subtitle": "Section 8.5", "enabled": false},
	{"id": "cs.u08.creating-content.headings", "title": "Headings", "subtitle": "Section 8.5.1", "enabled": false},
	{"id": "cs.u08.creating-content.headings.example", "title": "Example", "subtitle": "Section 8.5.1.1", "enabled": false},
	{"id": "cs.u08.creating-content.paragraphs", "title": "Paragraphs", "subtitle": "Section 8.5.2", "enabled": false},
	{"id": "cs.u08.creating-content.links", "title": "Links", "subtitle": "Section 8.5.3", "enabled": false},
	{"id": "cs.u08.creating-content.images", "title": "Images", "subtitle": "Section 8.5.4", "enabled": false},
	{"id": "cs.u08.creating-content.lists", "title": "Lists", "subtitle": "Section 8.5.5", "enabled": false},
	{"id": "cs.u08.creating-content.lists.unordered", "title": "Unordered List", "subtitle": "Section 8.5.5.1", "enabled": false},
	{"id": "cs.u08.creating-content.lists.ordered", "title": "Ordered List", "subtitle": "Section 8.5.5.2", "enabled": false},
	{"id": "cs.u08.creating-content.tables", "title": "Creating Tables in HTML", "subtitle": "Section 8.5.6", "enabled": false},
	{"id": "cs.u08.creating-content.comments", "title": "HTML Comments", "subtitle": "Section 8.5.7", "enabled": false},
	{"id": "cs.u08.styling-css", "title": "8.6 Styling with CSS", "subtitle": "Section 8.6", "enabled": false},
	{"id": "cs.u08.styling-css.basic-structure", "title": "Basic Structure of CSS", "subtitle": "Section 8.6.1", "enabled": false},
	{"id": "cs.u08.styling-css.integrating-css", "title": "Integrating CSS in HTML", "subtitle": "Section 8.6.2", "enabled": false},
	{"id": "cs.u08.styling-css.styling-elements", "title": "Styling HTML Elements with Fonts, Colors, Backgrounds", "subtitle": "Section 8.6.4", "enabled": false},
	{"id": "cs.u08.styling-css.styling-backgrounds", "title": "Styling Backgrounds", "subtitle": "Section 8.6.3.1", "enabled": false},
	{"id": "cs.u08.styling-css.layouts", "title": "Creating Layouts and Organizing Content", "subtitle": "Section 8.6.4 (layouts)", "enabled": false},
	{"id": "cs.u08.styling-css.animations", "title": "Adding Animations and Transitions Using CSS", "subtitle": "Section 8.6.5", "enabled": false},
	{"id": "cs.u08.styling-css.animations.adding-animations", "title": "Adding Animations", "subtitle": "Section 8.6.5.1", "enabled": false},
	{"id": "cs.u08.styling-css.animations.adding-transitions", "title": "Adding Transitions", "subtitle": "Section 8.6.5.2", "enabled": false},
	{"id": "cs.u08.javascript", "title": "8.7 Introduction to JavaScript", "subtitle": "Section 8.7", "enabled": false},
	{"id": "cs.u08.javascript.basic-syntax", "title": "Basic Syntax and Examples", "subtitle": "Section 8.7.1", "enabled": false},
	{"id": "cs.u08.javascript.basic-syntax.variables-data-types", "title": "Variables and Data Types", "subtitle": "Section 8.7.1 (variables)", "enabled": false},
	{"id": "cs.u08.javascript.basic-syntax.declaring-variables", "title": "Declaring Variables", "subtitle": "Section 8.7.1.1", "enabled": false},
	{"id": "cs.u08.javascript.basic-syntax.dry-run-example", "title": "Dry Run Example", "subtitle": "Section 8.7.1.2", "enabled": false},
	{"id": "cs.u08.javascript.basic-syntax.data-types", "title": "Data Types", "subtitle": "Section 8.7.1.3", "enabled": false},
	{"id": "cs.u08.javascript.functions", "title": "Functions in JavaScript", "subtitle": "Section 8.7.2", "enabled": false},
	{"id": "cs.u08.javascript.functions.simple", "title": "Simple Function", "subtitle": "Section 8.7.2.1", "enabled": false},
	{"id": "cs.u08.javascript.functions.parameters", "title": "Function with Parameters", "subtitle": "Section 8.7.2.2", "enabled": false},
	{"id": "cs.u08.javascript.functions.multiple-parameters", "title": "Function with Multiple Parameters", "subtitle": "Section 8.7.2.3", "enabled": false},
	{"id": "cs.u08.javascript.events-user-input", "title": "Handling Events and User Input", "subtitle": "Section 8.7.3", "enabled": false},
	{"id": "cs.u08.javascript.events-user-input.managing-events", "title": "Managing Events and User Interactions with JavaScript", "subtitle": "Section 8.7.3.1", "enabled": false},
	{"id": "cs.u08.javascript.interactive-elements", "title": "Creating Interactive Elements", "subtitle": "Section 8.7.4", "enabled": false},
	{"id": "cs.u08.javascript.interactive-elements.simple-programs-forms", "title": "Developing Simple Programs and Forms", "subtitle": "Section 8.7.4.1", "enabled": false},
	{"id": "cs.u08.javascript.interactive-elements.integrating-html", "title": "Integrating JavaScript with HTML for Interactive Functionality", "subtitle": "Section 8.7.4.2", "enabled": false},
	{"id": "cs.u08.developing-debugging", "title": "8.8 Developing and Debugging", "subtitle": "Section 8.8", "enabled": false},
	{"id": "cs.u08.developing-debugging.techniques", "title": "Debugging Techniques", "subtitle": "Section 8.8.1", "enabled": false},
	{"id": "cs.u08.developing-debugging.common-issues", "title": "Identifying and Fixing Common Issues", "subtitle": "Section 8.8.2", "enabled": false},
	{"id": "cs.u08.developing-debugging.deploying-testing", "title": "Deploying and Testing", "subtitle": "Section 8.8.3", "enabled": false},
	{"id": "cs.u08.developing-debugging.deploying-testing.strategies", "title": "Strategies for Testing Web Pages", "subtitle": "Section 8.8.3.1", "enabled": false},
	{"id": "cs.u08.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u08.mcqs", "title": "Multiple Choice Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u08.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u08.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT9_TOPICS := [
	{"id": "cs.u09.data", "title": "9.1 Data", "subtitle": "Section 9.1", "enabled": false},
	{"id": "cs.u09.data-types", "title": "9.2 Data Types", "subtitle": "Section 9.2", "enabled": false},
	{"id": "cs.u09.data-types.qualitative", "title": "Qualitative Data", "subtitle": "Section 9.2.1", "enabled": false},
	{"id": "cs.u09.data-types.quantitative", "title": "Quantitative Data", "subtitle": "Section 9.2.2", "enabled": false},
	{"id": "cs.u09.organising-analysing-data", "title": "9.3 Organising and Analysing Data", "subtitle": "Section 9.3", "enabled": false},
	{"id": "cs.u09.organising-analysing-data.data-collection", "title": "Data Collection", "subtitle": "Section 9.3.1", "enabled": false},
	{"id": "cs.u09.organising-analysing-data.data-collection.online-sources", "title": "Gathering Data from Online Sources", "subtitle": "Section 9.3.1.1", "enabled": false},
	{"id": "cs.u09.data-structure-types", "title": "9.4 Data Types (Structured and Unstructured)", "subtitle": "Section 9.4", "enabled": false},
	{"id": "cs.u09.data-structure-types.structured", "title": "Structured Data", "subtitle": "Section 9.4.1", "enabled": false},
	{"id": "cs.u09.data-structure-types.unstructured", "title": "Unstructured Data", "subtitle": "Section 9.4.2", "enabled": false},
	{"id": "cs.u09.data-storage-techniques", "title": "9.5 Data Storage Techniques", "subtitle": "Section 9.5", "enabled": false},
	{"id": "cs.u09.data-storage-techniques.spreadsheets", "title": "Spreadsheets", "subtitle": "Section 9.5.1", "enabled": false},
	{"id": "cs.u09.data-storage-techniques.databases", "title": "Databases", "subtitle": "Section 9.5.2", "enabled": false},
	{"id": "cs.u09.data-storage-techniques.data-warehouses", "title": "Data Warehouses", "subtitle": "Section 9.5.3", "enabled": false},
	{"id": "cs.u09.data-storage-techniques.nosql", "title": "NoSQL", "subtitle": "Section 9.5.4", "enabled": false},
	{"id": "cs.u09.data-visualization", "title": "9.6 Data Visualization", "subtitle": "Section 9.6", "enabled": false},
	{"id": "cs.u09.data-visualization.importance", "title": "Importance and Benefits of Data Visualization", "subtitle": "Section 9.6.1", "enabled": false},
	{"id": "cs.u09.data-visualization.data-types", "title": "Visualizing Different Data Types", "subtitle": "Section 9.6.2", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis", "title": "9.7 Data Pre-Processing and Analysis", "subtitle": "Section 9.7", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis.pre-processing", "title": "Data Pre-processing", "subtitle": "Section 9.7.1", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis.pre-processing.techniques", "title": "Data Pre-processing Techniques", "subtitle": "Section 9.7.1.1", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis.validation-cleaning", "title": "Implementing Data Validation and Cleaning Processes", "subtitle": "Section 9.7.2", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis.analysis-techniques", "title": "Data Analysis Techniques", "subtitle": "Section 9.7.3", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis.analysis-techniques.quantitative", "title": "Quantitative Analysis", "subtitle": "Section 9.7.3.1", "enabled": false},
	{"id": "cs.u09.pre-processing-analysis.analysis-techniques.qualitative", "title": "Qualitative Analysis", "subtitle": "Section 9.7.3.2", "enabled": false},
	{"id": "cs.u09.collaborative-tools-cloud", "title": "9.8 Collaborative Tools and Cloud Storage", "subtitle": "Section 9.8", "enabled": false},
	{"id": "cs.u09.collaborative-tools-cloud.cloud-storage", "title": "Cloud Storage for Data Management", "subtitle": "Section 9.8.1", "enabled": false},
	{"id": "cs.u09.collaborative-tools-cloud.remote-access", "title": "Remote Access", "subtitle": "Section 9.8.2", "enabled": false},
	{"id": "cs.u09.collaborative-tools-cloud.backups", "title": "Data Backups", "subtitle": "Section 9.8.3", "enabled": false},
	{"id": "cs.u09.collaborative-tools-cloud.authoring", "title": "Collaborative Authoring", "subtitle": "Section 9.8.4", "enabled": false},
	{"id": "cs.u09.collaborative-tools-cloud.benefits", "title": "Benefits of Collaborative Tools", "subtitle": "Section 9.8.5", "enabled": false},
	{"id": "cs.u09.introduction-data-science", "title": "9.9 Introduction to Data Science", "subtitle": "Section 9.9", "enabled": false},
	{"id": "cs.u09.introduction-data-science.understanding", "title": "Understanding Data Science", "subtitle": "Section 9.9.1", "enabled": false},
	{"id": "cs.u09.introduction-data-science.interdisciplinary", "title": "Interdisciplinary Nature of Data Science", "subtitle": "Section 9.9.2", "enabled": false},
	{"id": "cs.u09.introduction-data-science.workflow", "title": "Data Science Workflow", "subtitle": "Section 9.9.3", "enabled": false},
	{"id": "cs.u09.big-data", "title": "9.10 Big Data and its Applications", "subtitle": "Section 9.10", "enabled": false},
	{"id": "cs.u09.big-data.introduction", "title": "Introduction to Big Data", "subtitle": "Section 9.10.1", "enabled": false},
	{"id": "cs.u09.big-data.applications", "title": "Practical Applications of Big Data", "subtitle": "Section 9.10.2", "enabled": false},
	{"id": "cs.u09.big-data.tools-techniques", "title": "Tools and Techniques in Data Science", "subtitle": "Section 9.10.3", "enabled": false},
	{"id": "cs.u09.big-data.tools-techniques.tools", "title": "Data Science Tools", "subtitle": "Section 9.10.3.1", "enabled": false},
	{"id": "cs.u09.big-data.tools-techniques.techniques", "title": "Data Science Techniques", "subtitle": "Section 9.10.3.2", "enabled": false},
	{"id": "cs.u09.big-data.tools-techniques.applications", "title": "Applications of Data Science Techniques", "subtitle": "Section 9.10.3.3", "enabled": false},
	{"id": "cs.u09.big-data.tools-techniques.predictions", "title": "Predictions for the Future of Digital Tools in Data Management and Analysis", "subtitle": "Section 9.10.3.4", "enabled": false},
	{"id": "cs.u09.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u09.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u09.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u09.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT10_TOPICS := [
	{"id": "cs.u10.introduction-ai", "title": "10.1 Introduction to Artificial Intelligence (AI)", "subtitle": "Section 10.1", "enabled": false},
	{"id": "cs.u10.introduction-ai.understanding", "title": "Understanding AI", "subtitle": "Section 10.1.1", "enabled": false},
	{"id": "cs.u10.introduction-ai.historical-context", "title": "Historical Context of Artificial Intelligence", "subtitle": "Section 10.1.2", "enabled": false},
	{"id": "cs.u10.introduction-ai.applications-subfields", "title": "Applications and Subfields", "subtitle": "Section 10.1.3", "enabled": false},
	{"id": "cs.u10.ai-algorithms", "title": "10.2 AI Algorithms and Techniques", "subtitle": "Section 10.2", "enabled": false},
	{"id": "cs.u10.ai-algorithms.types", "title": "Types of AI Algorithms", "subtitle": "Section 10.2.1", "enabled": false},
	{"id": "cs.u10.ai-algorithms.types.explainable", "title": "Explainable (Whitebox) Algorithms", "subtitle": "Section 10.2.1.1", "enabled": false},
	{"id": "cs.u10.ai-algorithms.types.unexplainable", "title": "Unexplainable (Blackbox) Algorithms", "subtitle": "Section 10.2.1.2", "enabled": false},
	{"id": "cs.u10.introduction-iot", "title": "10.3 Introduction to Internet of Things (IoT)", "subtitle": "Section 10.3", "enabled": false},
	{"id": "cs.u10.introduction-iot.understanding", "title": "Understanding IoT", "subtitle": "Section 10.3.1", "enabled": false},
	{"id": "cs.u10.introduction-iot.understanding.definition-components", "title": "Definition and Components", "subtitle": "Section 10.3.1.1", "enabled": false},
	{"id": "cs.u10.introduction-iot.applications", "title": "IoT Applications", "subtitle": "Section 10.3.2", "enabled": false},
	{"id": "cs.u10.introduction-iot.security-privacy", "title": "Security and Privacy Considerations in IoT Deployments", "subtitle": "Section 10.3.3", "enabled": false},
	{"id": "cs.u10.implications-future", "title": "10.4 Implications and Future of Emerging Technologies", "subtitle": "Section 10.4", "enabled": false},
	{"id": "cs.u10.implications-future.implications", "title": "Implications of AI and IoT", "subtitle": "Section 10.4.1", "enabled": false},
	{"id": "cs.u10.implications-future.implications.risks-challenges", "title": "Risks and Challenges", "subtitle": "Section 10.4.1.1", "enabled": false},
	{"id": "cs.u10.implications-future.implications.societal-impact", "title": "Societal Impact and Adaptation", "subtitle": "Section 10.4.1.2", "enabled": false},
	{"id": "cs.u10.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u10.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u10.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u10.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT11_TOPICS := [
	{"id": "cs.u11.responsible-usage", "title": "11.1 Responsible Computer Usage", "subtitle": "Section 11.1", "enabled": false},
	{"id": "cs.u11.safe-secure-operation", "title": "11.2 Safe and Secure Operation of Digital Platforms", "subtitle": "Section 11.2", "enabled": false},
	{"id": "cs.u11.safe-secure-operation.safe-operation", "title": "Safe Operation of Digital Platforms and Devices", "subtitle": "Section 11.2.1", "enabled": false},
	{"id": "cs.u11.safe-secure-operation.secure-use", "title": "Secure Use of Digital Platforms", "subtitle": "Section 11.2.2", "enabled": false},
	{"id": "cs.u11.best-practices", "title": "11.3 Best Practices in Online Behavior", "subtitle": "Section 11.3", "enabled": false},
	{"id": "cs.u11.best-practices.responsible-use", "title": "Responsible Use of Social Media, Email, Cloud Services, and Online Platforms", "subtitle": "Section 11.3.1", "enabled": false},
	{"id": "cs.u11.best-practices.privacy-security", "title": "Importance of Privacy Settings and Data Security Measures", "subtitle": "Section 11.3.2", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks", "title": "11.4 Legal and Ethical Frameworks", "subtitle": "Section 11.4", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.privacy-laws", "title": "Legal Frameworks for Privacy", "subtitle": "Section 11.4.1", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.privacy-laws.understanding", "title": "Understanding Privacy Laws and Their Implications", "subtitle": "Section 11.4.1.1", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.privacy-laws.protection", "title": "Laws Protecting User Privacy and Consequences of Unauthorized Access", "subtitle": "Section 11.4.1.2", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.data-ethics", "title": "Data Ethics and Responsible Use", "subtitle": "Section 11.4.2", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.data-ethics.introduction", "title": "Introduction to Data Ethics and Principles Governing Data", "subtitle": "Section 11.4.2.1", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.data-ethics.considerations", "title": "Ethical Considerations in Data Collection, Storage, and Sharing", "subtitle": "Section 11.4.2.2", "enabled": false},
	{"id": "cs.u11.legal-ethical-frameworks.data-ethics.guidelines", "title": "Ethical Guidelines for Data Usage and Management", "subtitle": "Section 11.4.2.3", "enabled": false},
	{"id": "cs.u11.intellectual-property", "title": "11.5 Intellectual Property Rights", "subtitle": "Section 11.5", "enabled": false},
	{"id": "cs.u11.intellectual-property.concepts", "title": "Concepts of Intellectual Property", "subtitle": "Section 11.5.1", "enabled": false},
	{"id": "cs.u11.intellectual-property.concepts.significance", "title": "Copyright, Trademarks, Patents, and Their Significance in Digital World", "subtitle": "Section 11.5.1.1", "enabled": false},
	{"id": "cs.u11.intellectual-property.concepts.responsibilities", "title": "Ethical and Legal Responsibilities Regarding Intellectual Property", "subtitle": "Section 11.5.1.2", "enabled": false},
	{"id": "cs.u11.intellectual-property.legal-compliance", "title": "Legal Compliance in Computing", "subtitle": "Section 11.5.2", "enabled": false},
	{"id": "cs.u11.responsible-internet-use", "title": "11.6 Responsible Internet Use", "subtitle": "Section 11.6", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.safe-searches", "title": "Safe Data Searches and Online Research", "subtitle": "Section 11.6.1", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.safe-searches.techniques", "title": "Techniques for Safe Data Searches and Credibility Assessment", "subtitle": "Section 11.6.1.1", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.safe-searches.privacy-risks", "title": "Avoiding Privacy Risks During Online Research and Information Sharing", "subtitle": "Section 11.6.1.2", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.internet-addiction", "title": "Preventing Internet Addiction", "subtitle": "Section 11.6.2", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.internet-addiction.understanding", "title": "Understanding Internet Addiction and Promoting Balanced Usage", "subtitle": "Section 11.6.2.1", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.internet-addiction.strategies", "title": "Strategies for Digital Well-being and Fostering Healthy Online Habits", "subtitle": "Section 11.6.2.2", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.social-networking", "title": "Social Networking Safety and Online Interactions", "subtitle": "Section 11.6.3", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.social-networking.privacy-etiquette", "title": "Privacy Settings, Responsible Sharing, and Online Etiquette", "subtitle": "Section 11.6.3.1", "enabled": false},
	{"id": "cs.u11.responsible-internet-use.social-networking.cyberbullying", "title": "Addressing Cyberbullying, Harassment, and Respectful Online Communication", "subtitle": "Section 11.6.3.2", "enabled": false},
	{"id": "cs.u11.impact-on-society", "title": "11.7 Impact of Computing on Society", "subtitle": "Section 11.7", "enabled": false},
	{"id": "cs.u11.impact-on-society.behaviors", "title": "Influence on Behaviors and Practices", "subtitle": "Section 11.7.1", "enabled": false},
	{"id": "cs.u11.impact-on-society.behaviors.dimensions", "title": "Environmental, Ethical, Legal, Societal, Economic, and Cultural Impacts", "subtitle": "Section 11.7.1.1", "enabled": false},
	{"id": "cs.u11.impact-on-society.behaviors.global-role", "title": "Role of Computing in Global Trade, Communication, and Cultural Exchange", "subtitle": "Section 11.7.1.2", "enabled": false},
	{"id": "cs.u11.impact-on-society.assessing-advancements", "title": "Assessing Computing Advancements", "subtitle": "Section 11.7.2", "enabled": false},
	{"id": "cs.u11.impact-on-society.assessing-advancements.benefits-risks", "title": "Benefits and Risks of Computing Advancements (Social)", "subtitle": "Section 11.7.2.1", "enabled": false},
	{"id": "cs.u11.impact-on-society.assessing-advancements.trade-offs", "title": "Trade-offs Between Privacy, Security, and Usability in Computing", "subtitle": "Section 11.7.2.2", "enabled": false},
	{"id": "cs.u11.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u11.mcqs", "title": "Multiple Choice Questions (MCQs)", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u11.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u11.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const CS_UNIT12_TOPICS := [
	{"id": "cs.u12.entrepreneurship", "title": "12.1 Entrepreneurship", "subtitle": "Section 12.1", "enabled": false},
	{"id": "cs.u12.entrepreneurship.examples", "title": "Examples of Entrepreneurship", "subtitle": "Section 12.1.1", "enabled": false},
	{"id": "cs.u12.entrepreneurship.examples.tech-startups", "title": "Tech Startups", "subtitle": "Section 12.1.1 (a)", "enabled": false},
	{"id": "cs.u12.entrepreneurship.examples.local-businesses", "title": "Local Businesses", "subtitle": "Section 12.1.1 (b)", "enabled": false},
	{"id": "cs.u12.entrepreneurship.characteristics", "title": "Key Characteristics of Entrepreneurs", "subtitle": "Section 12.1.2", "enabled": false},
	{"id": "cs.u12.entrepreneurship.characteristics.innovation", "title": "Innovation", "subtitle": "Section 12.1.2 (a)", "enabled": false},
	{"id": "cs.u12.entrepreneurship.characteristics.risk-taking", "title": "Risk-Taking", "subtitle": "Section 12.1.2 (b)", "enabled": false},
	{"id": "cs.u12.entrepreneurship.importance", "title": "Why is Entrepreneurship Important?", "subtitle": "Section 12.1.3", "enabled": false},
	{"id": "cs.u12.entrepreneurship.importance.economic-growth", "title": "Economic Growth", "subtitle": "Section 12.1.3.1", "enabled": false},
	{"id": "cs.u12.entrepreneurship.importance.innovation-progress", "title": "Innovation and Progress", "subtitle": "Section 12.1.3.2", "enabled": false},
	{"id": "cs.u12.digital-landscape", "title": "12.2 Entrepreneurship in the Digital Landscape", "subtitle": "Section 12.2", "enabled": false},
	{"id": "cs.u12.digital-landscape.transformation", "title": "Digital Transformation and Entrepreneurship", "subtitle": "Section 12.2.1", "enabled": false},
	{"id": "cs.u12.digital-landscape.digital-technologies", "title": "Role of Digital Technologies", "subtitle": "Section 12.2.2", "enabled": false},
	{"id": "cs.u12.digital-landscape.digital-technologies.social-media", "title": "Social Media", "subtitle": "Section 12.2.2.1", "enabled": false},
	{"id": "cs.u12.digital-landscape.digital-technologies.mobile-apps", "title": "Mobile Apps", "subtitle": "Section 12.2.2.2", "enabled": false},
	{"id": "cs.u12.digital-landscape.digital-technologies.cloud", "title": "Cloud Computing", "subtitle": "Section 12.2.2.3", "enabled": false},
	{"id": "cs.u12.digital-landscape.digital-technologies.big-data", "title": "Big Data Analytics", "subtitle": "Section 12.2.2.4", "enabled": false},
	{"id": "cs.u12.digital-landscape.digital-technologies.marketing-ecommerce", "title": "Digital Marketing and E-commerce", "subtitle": "Section 12.2.2.5", "enabled": false},
	{"id": "cs.u12.digital-landscape.e-commerce-platforms", "title": "E-commerce Platforms", "subtitle": "Section 12.2.3", "enabled": false},
	{"id": "cs.u12.digital-landscape.case-studies", "title": "Case Studies", "subtitle": "Section 12.2.4 (studies)", "enabled": false},
	{"id": "cs.u12.digital-landscape.case-studies.daraz", "title": "Daraz", "subtitle": "Section 12.2.4.1", "enabled": false},
	{"id": "cs.u12.digital-landscape.case-studies.bykea", "title": "Bykea", "subtitle": "Section 12.2.4.2", "enabled": false},
	{"id": "cs.u12.digital-landscape.challenges-opportunities", "title": "Challenges and Opportunities", "subtitle": "Section 12.2.4 (closing)", "enabled": false},
	{"id": "cs.u12.digital-landscape.challenges-opportunities.opportunities", "title": "Opportunities", "subtitle": "Section 12.2.4.1", "enabled": false},
	{"id": "cs.u12.digital-landscape.challenges-opportunities.challenges", "title": "Challenges", "subtitle": "Section 12.2.4.2", "enabled": false},
	{"id": "cs.u12.digital-tools-platforms", "title": "12.3 Digital Tools and Platforms", "subtitle": "Section 12.3", "enabled": false},
	{"id": "cs.u12.digital-tools-platforms.overview", "title": "Overview of Digital Tools", "subtitle": "Section 12.3.1", "enabled": false},
	{"id": "cs.u12.digital-tools-platforms.market-research", "title": "Market Research Tools", "subtitle": "Section 12.3.2", "enabled": false},
	{"id": "cs.u12.digital-tools-platforms.online-marketing", "title": "Online Marketing Tools", "subtitle": "Section 12.3.3 (marketing)", "enabled": false},
	{"id": "cs.u12.digital-tools-platforms.e-commerce", "title": "E-commerce Platforms", "subtitle": "Section 12.3.3 (e-commerce)", "enabled": false},
	{"id": "cs.u12.business-idea-generation", "title": "12.4 Business Idea Generation", "subtitle": "Section 12.4", "enabled": false},
	{"id": "cs.u12.business-idea-generation.ideation", "title": "Ideation and Problem Solving", "subtitle": "Section 12.4.1", "enabled": false},
	{"id": "cs.u12.business-idea-generation.problem-identification", "title": "Problem Identification", "subtitle": "Section 12.4.2", "enabled": false},
	{"id": "cs.u12.business-idea-generation.creative-problem-solving", "title": "Creative Problem Solving", "subtitle": "Section 12.4.3", "enabled": false},
	{"id": "cs.u12.business-plans", "title": "12.5 Developing Business Plans", "subtitle": "Section 12.5", "enabled": false},
	{"id": "cs.u12.business-plans.comprehensive-plans", "title": "Creating Comprehensive Business Plans", "subtitle": "Section 12.5.1", "enabled": false},
	{"id": "cs.u12.business-plans.components", "title": "Components of a Business Plan", "subtitle": "Section 12.5.2", "enabled": false},
	{"id": "cs.u12.business-plans.prototyping", "title": "Prototyping and Iteration", "subtitle": "Section 12.5.3", "enabled": false},
	{"id": "cs.u12.ethical-sustainable", "title": "12.6 Ethical and Sustainable Entrepreneurship", "subtitle": "Section 12.6", "enabled": false},
	{"id": "cs.u12.ethical-sustainable.ethical-practices", "title": "Ethical Practices and Sustainable Growth", "subtitle": "Section 12.6.1", "enabled": false},
	{"id": "cs.u12.ethical-sustainable.ethical-entrepreneurship", "title": "Ethical Entrepreneurship", "subtitle": "Section 12.6.2", "enabled": false},
	{"id": "cs.u12.ethical-sustainable.sdgs", "title": "Sustainable Development Goals (SDGs)", "subtitle": "Section 12.6.4", "enabled": false},
	{"id": "cs.u12.summary", "title": "Summary", "subtitle": "Unit review", "enabled": false},
	{"id": "cs.u12.mcqs", "title": "Multiple Choice Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u12.short-questions", "title": "Short Questions", "subtitle": "Assessment", "enabled": false},
	{"id": "cs.u12.long-questions", "title": "Long Questions", "subtitle": "Assessment", "enabled": false},
]

const TARGET_TOPIC := "math.u01.real-numbers.rational-irrational-combination"
const TARGET_SCENE := "res://main.tscn"

## Lesson MVP: tapping this topic opens the offline lesson scene instead of
## the 3D world. All other topics keep their current behavior.
const LESSON_TOPIC := "math.u01.real-numbers"
const LESSON_SCENE := "res://scenes/lesson.tscn"

const SLIDE_TIME := 0.22

const CARD_BG := Color(0.106, 0.129, 0.22)
const CARD_HOVER := Color(0.145, 0.176, 0.3)
const CARD_PRESSED := Color(0.086, 0.11, 0.19)
const CARD_DISABLED := Color(0.082, 0.098, 0.16)
const ACCENT := Color(0.42, 0.55, 1)
const PILL_MUTED := Color(0.3, 0.33, 0.45)
const TEXT_PRIMARY := Color(0.95, 0.96, 1)
const TEXT_MUTED := Color(0.6, 0.64, 0.78)
const TEXT_DISABLED := Color(0.5, 0.53, 0.65)

## Chapters grid per subject (kept separate so Math data stays untouched).
const _CHAPTERS_BY_SUBJECT := {
	"math": MATH_CHAPTERS,
	"computer-science": CS_UNITS,
}

const _TOPICS_BY_UNIT := {
	"math.u01": UNIT1_TOPICS,
	"math.u02": UNIT2_TOPICS,
	"math.u03": UNIT3_TOPICS,
	"math.u04": UNIT4_TOPICS,
	"math.u05": UNIT5_TOPICS,
	"math.u06": UNIT6_TOPICS,
	"math.u07": UNIT7_TOPICS,
	"math.u08": UNIT8_TOPICS,
	"math.u09": UNIT9_TOPICS,
	"math.u10": UNIT10_TOPICS,
	"math.u11": UNIT11_TOPICS,
	"math.u12": UNIT12_TOPICS,
	"math.u13": UNIT13_TOPICS,
	"cs.u01": CS_UNIT1_TOPICS,
	"cs.u02": CS_UNIT2_TOPICS,
	"cs.u03": CS_UNIT3_TOPICS,
	"cs.u04": CS_UNIT4_TOPICS,
	"cs.u05": CS_UNIT5_TOPICS,
	"cs.u06": CS_UNIT6_TOPICS,
	"cs.u07": CS_UNIT7_TOPICS,
	"cs.u08": CS_UNIT8_TOPICS,
	"cs.u09": CS_UNIT9_TOPICS,
	"cs.u10": CS_UNIT10_TOPICS,
	"cs.u11": CS_UNIT11_TOPICS,
	"cs.u12": CS_UNIT12_TOPICS,
}

const _PREVIEW_SIZE := Vector2(360, 640)

@onready var _content: Control = %Content
@onready var _grid: GridContainer = %Grid
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _back_button: Button = %BackButton

var _state: int = MenuState.SUBJECTS
var _busy := false
var _content_home := Vector2.ZERO
var _preview_root: Control = null
var _current_subject_id := ""
var _current_unit_id := ""


func _ready() -> void:
	if Engine.is_editor_hint():
		_build_editor_preview()
		return
	_content_home = _content.position
	_back_button.pressed.connect(_go_back)
	_apply_state(MenuState.SUBJECTS)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		_clear_editor_preview()


## Editor-safe preview: renders the subjects grid with placeholders so the
## layout is visible in the editor. Never touches LearningSession, tweens,
## or scene changes, and is fully cleared on exit.
func _build_editor_preview() -> void:
	_clear_editor_preview()
	if _grid == null:
		return
	_preview_root = Control.new()
	_preview_root.name = "MenuPreview"
	add_child(_preview_root)

	var viewport_bg := ColorRect.new()
	viewport_bg.name = "PreviewBackground"
	viewport_bg.color = Color(0.039, 0.055, 0.102, 1)
	viewport_bg.size = _PREVIEW_SIZE
	_preview_root.add_child(viewport_bg)

	var frame := Control.new()
	frame.name = "PreviewFrame"
	frame.position = Vector2(18, 20)
	frame.size = Vector2(_PREVIEW_SIZE.x - 36.0, _PREVIEW_SIZE.y - 40.0)
	_preview_root.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.name = "PreviewVBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	frame.add_child(vbox)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	vbox.add_child(header)

	var title := Label.new()
	title.name = "PreviewTitle"
	title.text = "Angelix"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "PreviewSubtitle"
	subtitle.text = "9th Grade (PCTB) - PREVIEW"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	header.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.name = "PreviewScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "PreviewGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for entry in SUBJECTS:
		grid.add_child(_make_card(entry))


func _clear_editor_preview() -> void:
	if is_instance_valid(_preview_root):
		_preview_root.queue_free()
	_preview_root = null


func _on_card_pressed(item_id: String) -> void:
	if _busy:
		return
	match _state:
		MenuState.SUBJECTS:
			if _CHAPTERS_BY_SUBJECT.has(item_id):
				_current_subject_id = item_id
				_slide_to_state(MenuState.CHAPTERS)
		MenuState.CHAPTERS:
			if _TOPICS_BY_UNIT.has(item_id):
				_current_unit_id = item_id
				_slide_to_state(MenuState.TOPICS)
		MenuState.TOPICS:
			if item_id == LESSON_TOPIC:
				get_tree().change_scene_to_file(LESSON_SCENE)
			elif item_id == TARGET_TOPIC:
				get_tree().change_scene_to_file(TARGET_SCENE)


func _go_back() -> void:
	if _busy:
		return
	if _state == MenuState.TOPICS:
		_slide_to_state(MenuState.CHAPTERS, false)
	elif _state == MenuState.CHAPTERS:
		_slide_to_state(MenuState.SUBJECTS, false)


func _apply_state(new_state: int) -> void:
	_state = new_state
	_refresh_header()
	_repopulate()


## Slides the whole content out, repopulates the grid, slides it back in.
## Forward = content exits left / enters from right; back = the reverse.
func _slide_to_state(new_state: int, forward: bool = true) -> void:
	if _busy or new_state == _state:
		return
	_busy = true

	var width := _content.size.x
	var out_x := _content_home.x - width if forward else _content_home.x + width
	var in_x := _content_home.x + width if forward else _content_home.x - width

	var out_tween := create_tween()
	out_tween.tween_property(_content, "position:x", out_x, SLIDE_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await out_tween.finished

	_apply_state(new_state)
	_content.position = Vector2(in_x, _content_home.y)

	var in_tween := create_tween()
	in_tween.tween_property(_content, "position:x", _content_home.x, SLIDE_TIME) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await in_tween.finished

	_busy = false


func _refresh_header() -> void:
	match _state:
		MenuState.SUBJECTS:
			_title_label.text = "Angelix"
			_subtitle_label.text = "9th Grade (PCTB) - Select a subject"
			_back_button.visible = false
		MenuState.CHAPTERS:
			_title_label.text = _current_subject_title()
			_subtitle_label.text = "Select a unit"
			_back_button.visible = true
		MenuState.TOPICS:
			_title_label.text = _current_unit_title()
			_subtitle_label.text = "Topics and exercises (book order)"
			_back_button.visible = true


func _current_subject_title() -> String:
	for entry in SUBJECTS:
		if entry["id"] == _current_subject_id:
			return String(entry["title"])
	return "Chapters"


func _current_unit_title() -> String:
	var chapters: Array = _CHAPTERS_BY_SUBJECT.get(_current_subject_id, [])
	for entry in chapters:
		if entry["id"] == _current_unit_id:
			return String(entry["title"]) + " - " + String(entry["subtitle"])
	return "Topics"


func _topic_entries_for_state() -> Array:
	var entries: Array = []
	match _state:
		MenuState.SUBJECTS:
			entries = SUBJECTS
		MenuState.CHAPTERS:
			entries = _CHAPTERS_BY_SUBJECT.get(_current_subject_id, [])
		MenuState.TOPICS:
			entries = _TOPICS_BY_UNIT.get(_current_unit_id, [])
	return entries


func _repopulate() -> void:
	for child in _grid.get_children():
		child.queue_free()

	for entry in _topic_entries_for_state():
		_grid.add_child(_make_card(entry))


func _make_card(entry: Dictionary) -> Button:
	var enabled: bool = entry.get("enabled", true)

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 96)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not enabled

	var radius := 18
	card.add_theme_stylebox_override("normal", _card_style(CARD_BG, radius))
	card.add_theme_stylebox_override("hover", _card_style(CARD_HOVER, radius))
	card.add_theme_stylebox_override("pressed", _card_style(CARD_PRESSED, radius))
	card.add_theme_stylebox_override("disabled", _card_style(CARD_DISABLED, radius))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18.0
	box.offset_top = 12.0
	box.offset_right = -14.0
	box.offset_bottom = -12.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var pill := Panel.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = ACCENT if enabled else PILL_MUTED
	pill_style.set_corner_radius_all(2)
	pill.add_theme_stylebox_override("panel", pill_style)
	pill.custom_minimum_size = Vector2(30, 4)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pill)

	var title := Label.new()
	title.text = String(entry["title"])
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", TEXT_PRIMARY if enabled else TEXT_DISABLED)
	box.add_child(title)

	var subtitle_text := String(entry.get("subtitle", ""))
	if subtitle_text != "":
		var subtitle := Label.new()
		subtitle.text = subtitle_text
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.add_theme_font_size_override("font_size", 13)
		subtitle.add_theme_color_override(
			"font_color", TEXT_MUTED if enabled else TEXT_DISABLED)
		box.add_child(subtitle)

	if not Engine.is_editor_hint():
		card.pressed.connect(_on_card_pressed.bind(String(entry["id"])))
	return card


func _card_style(bg: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	return style
