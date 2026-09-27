@tool
extends CanvasLayer
## Linear menu flow: subjects -> math chapters -> chapter 2 topics -> 3D terrain.
## State 0 = subjects, State 1 = chapters, State 2 = topics.
##
## Curriculum data is transcribed from the PCTB Mathematics-9 textbook
## (Punjab Curriculum and Textbook Board, Lahore), extracted via OCR from
## page1-150.pdf and page151-288.pdf (288 scanned pages, 13 units).
## Source PDFs: https://github.com/Afra-Batool407/PCTB-Books

enum MenuState { SUBJECTS = 0, CHAPTERS = 1, TOPICS = 2 }

# ---------------------------------------------------------------
# Global configuration matrix (PCTB Mathematics-9, exact book order)
# IDs are stable (math.uXX.[topic-slug]) and separate from display
# titles; locked entries are content not yet built for the 3D world.
# ---------------------------------------------------------------
const SUBJECTS := [
	{"id": "math", "title": "Math", "subtitle": "13 units", "enabled": true},
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
	{"id": "math.u01.real-numbers", "title": "1.1 Introduction to Real Numbers", "subtitle": "Section 1.1", "enabled": false},
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

const TARGET_TOPIC := "math.u01.real-numbers.rational-irrational-combination"
const TARGET_SCENE := "res://main.tscn"

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
			if item_id == "math":
				_slide_to_state(MenuState.CHAPTERS)
		MenuState.CHAPTERS:
			if _TOPICS_BY_UNIT.has(item_id):
				_current_unit_id = item_id
				_slide_to_state(MenuState.TOPICS)
		MenuState.TOPICS:
			if item_id == TARGET_TOPIC:
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
			_title_label.text = "Mathematics"
			_subtitle_label.text = "13 units (PCTB Mathematics-9)"
			_back_button.visible = true
		MenuState.TOPICS:
			_title_label.text = _current_unit_title()
			_subtitle_label.text = "Topics and exercises (book order)"
			_back_button.visible = true


func _current_unit_title() -> String:
	for entry in MATH_CHAPTERS:
		if entry["id"] == _current_unit_id:
			return String(entry["title"]) + " - " + String(entry["subtitle"])
	return "Topics"


func _topic_entries_for_state() -> Array:
	var entries: Array = []
	match _state:
		MenuState.SUBJECTS:
			entries = SUBJECTS
		MenuState.CHAPTERS:
			entries = MATH_CHAPTERS
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
