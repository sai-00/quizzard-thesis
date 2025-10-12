PRAGMA foreign_keys = ON;

-- ======================
-- TABLE: userProfile
-- ======================
CREATE TABLE userProfile (
    profileID INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    avatar TEXT
);

-- ======================
-- TABLE: subject
-- ======================
CREATE TABLE subject (
    subjID INTEGER PRIMARY KEY AUTOINCREMENT,
    subjName TEXT NOT NULL
);

-- ======================
-- TABLE: questionList
-- ======================
CREATE TABLE questionList (
    questionID INTEGER PRIMARY KEY AUTOINCREMENT,
    subjID INTEGER NOT NULL,
    questionText TEXT NOT NULL,
    option1 TEXT NOT NULL,
    option2 TEXT NOT NULL,
    option3 TEXT NOT NULL,
    option4 TEXT NOT NULL,
    correctAnswer TEXT NOT NULL,
    correctExplanation TEXT,
    difficulty TEXT CHECK(difficulty IN ('Easy','Medium','Hard')),
    FOREIGN KEY (subjID) REFERENCES subject(subjID)
);

-- ======================
-- TABLE: gameProgress
-- ======================
CREATE TABLE gameProgress (
    gameProgID INTEGER PRIMARY KEY AUTOINCREMENT,
    profileID INTEGER NOT NULL,
    subjID INTEGER NOT NULL,
    questionID INTEGER NOT NULL,
    datePlayed TEXT,
    timeOn TEXT,
    timeOut TEXT,
    difficulty TEXT CHECK(difficulty IN ('Easy','Medium','Hard')),
    level INTEGER,
    points INTEGER DEFAULT 0,
    progressLevel TEXT,
    highestLevel TEXT,
    easyScore INTEGER,
    medScore INTEGER,
    hardScore INTEGER,
    playerAnswer TEXT,
    isCorrect INTEGER,
    FOREIGN KEY (profileID) REFERENCES userProfile(profileID),
    FOREIGN KEY (questionID) REFERENCES questionList(questionID),
    FOREIGN KEY (subjID) REFERENCES subject(subjID)
);

-- =========================================
-- INSERT SAMPLE DATA
-- =========================================

-- USERS
INSERT INTO userProfile (name, avatar) VALUES
('Himeko', ''),
('March', '');

-- SUBJECTS
INSERT INTO subject (subjName) VALUES
('Math'),
('Reading'),
('Science');

-- MATH QUESTIONS (20 total)
INSERT INTO questionList (subjID, questionText, option1, option2, option3, option4, correctAnswer, correctExplanation, difficulty) VALUES
(1, 'What is 2 + 3?', '4', '5', '6', '3', '5', '2 plus 3 equals 5.', 'Easy'),
(1, 'What is 9 - 4?', '3', '5', '4', '6', '5', 'Subtract 4 from 9 to get 5.', 'Easy'),
(1, 'Which number is even?', '3', '5', '6', '9', '6', 'Even numbers are divisible by 2.', 'Easy'),
(1, 'What is 10 / 2?', '2', '4', '5', '6', '5', '10 divided by 2 equals 5.', 'Medium'),
(1, 'Solve: 3 * 3', '6', '9', '8', '12', '9', 'Three times three equals nine.', 'Easy'),
(1, 'What is the next number after 14?', '13', '15', '16', '12', '15', 'The next integer after 14 is 15.', 'Easy'),
(1, 'What is half of 8?', '2', '3', '4', '5', '4', 'Half means divide by 2. 8 ÷ 2 = 4.', 'Easy'),
(1, 'Which is greater: 7 or 9?', '7', '9', 'equal', 'cannot tell', '9', '9 is larger than 7.', 'Easy'),
(1, 'What is 12 + 8?', '18', '19', '20', '22', '20', 'Twelve plus eight equals twenty.', 'Medium'),
(1, 'What is 5 * 6?', '25', '30', '20', '35', '30', 'Five times six equals thirty.', 'Medium'),
(1, 'Solve: 15 / 3', '3', '4', '5', '6', '5', 'Fifteen divided by three equals five.', 'Medium'),
(1, 'What is 9 * 9?', '81', '72', '99', '90', '81', 'Nine times nine equals eighty-one.', 'Hard'),
(1, 'Simplify: 20 - 8', '10', '12', '13', '14', '12', 'Subtract eight from twenty to get twelve.', 'Easy'),
(1, 'What is 7 + 8?', '14', '15', '16', '13', '15', 'Seven plus eight equals fifteen.', 'Easy'),
(1, 'If you have 3 apples and get 2 more, how many?', '4', '5', '6', '7', '5', '3 plus 2 equals 5.', 'Easy'),
(1, 'What is 50 / 10?', '4', '5', '6', '8', '5', 'Fifty divided by ten equals five.', 'Medium'),
(1, 'What is 4 * 5?', '10', '15', '20', '25', '20', 'Four times five equals twenty.', 'Medium'),
(1, 'Solve: 25 + 25', '40', '45', '50', '60', '50', '25 plus 25 equals fifty.', 'Hard'),
(1, 'Which is smaller: 3 or 5?', '3', '5', 'equal', 'none', '3', '3 is less than 5.', 'Easy'),
(1, 'What is 100 - 25?', '75', '70', '85', '65', '75', 'Subtract 25 from 100 to get 75.', 'Hard');

-- READING QUESTIONS (20 total)
INSERT INTO questionList (subjID, questionText, option1, option2, option3, option4, correctAnswer, correctExplanation, difficulty) VALUES
(2, 'Who is the main character in the story "The Little Red Hen"?', 'The dog', 'The cat', 'The hen', 'The cow', 'The hen', 'The title itself shows the main character.', 'Easy'),
(2, 'What did the hen want to bake?', 'Cake', 'Bread', 'Pie', 'Cookies', 'Bread', 'The story is about baking bread.', 'Easy'),
(2, 'What lesson does the story teach?', 'Be lazy', 'Work together', 'Be mean', 'Take shortcuts', 'Work together', 'The moral is about teamwork.', 'Medium'),
(2, 'In the sentence "The boy ran quickly," which word is the adverb?', 'boy', 'ran', 'quickly', 'the', 'quickly', 'Adverbs describe verbs — how something is done.', 'Medium'),
(2, 'What do you call words that name a person, place, or thing?', 'Verb', 'Adjective', 'Noun', 'Pronoun', 'Noun', 'Nouns name people, places, and things.', 'Easy'),
(2, 'What is the opposite of "happy"?', 'sad', 'joyful', 'angry', 'funny', 'sad', 'Sad is the antonym of happy.', 'Easy'),
(2, 'What does the word "enormous" mean?', 'tiny', 'huge', 'average', 'fast', 'huge', 'Enormous means very large.', 'Easy'),
(2, 'Which of these is a question?', 'The cat is black.', 'Where is my pen?', 'I like apples.', 'She runs fast.', 'Where is my pen?', 'Questions end with a question mark.', 'Easy'),
(2, 'What punctuation ends a question?', '.', '!', '?', ',', '?', 'Questions end with a question mark.', 'Easy'),
(2, 'Which word rhymes with "cat"?', 'dog', 'bat', 'cow', 'fish', 'bat', 'Bat rhymes with cat.', 'Easy'),
(2, 'What is the plural of "child"?', 'childs', 'children', 'childes', 'childies', 'children', 'Plural form of child is children.', 'Medium'),
(2, 'Find the synonym of "begin".', 'start', 'stop', 'end', 'pause', 'start', 'Start means the same as begin.', 'Medium'),
(2, 'Find the antonym of "fast".', 'slow', 'speedy', 'quick', 'rapid', 'slow', 'Opposite of fast is slow.', 'Easy'),
(2, 'What is the past tense of "go"?', 'goed', 'went', 'goes', 'gone', 'went', 'Past tense of go is went.', 'Medium'),
(2, 'Who wrote "The Three Little Pigs"?', 'Traditional', 'Shakespeare', 'Mark Twain', 'Hans Christian Andersen', 'Traditional', 'It is a traditional folk tale.', 'Hard'),
(2, 'What is a short story that teaches a lesson called?', 'Poem', 'Novel', 'Fable', 'Myth', 'Fable', 'Fables teach moral lessons.', 'Medium'),
(2, 'What sound does "sh" make in "ship"?', 's', 'ch', 'sh', 'th', 'sh', 'The digraph sh makes the /ʃ/ sound.', 'Easy'),
(2, 'What is the title of a book?', 'Author name', 'Illustration', 'Name of the story', 'Page number', 'Name of the story', 'The title is the story’s name.', 'Easy'),
(2, 'What do you call words that describe nouns?', 'Adverbs', 'Pronouns', 'Adjectives', 'Verbs', 'Adjectives', 'Adjectives describe nouns.', 'Medium'),
(2, 'How many syllables are in "banana"?', '1', '2', '3', '4', '3', 'Ba-na-na has three syllables.', 'Easy');

-- SCIENCE QUESTIONS (20 total)
INSERT INTO questionList (subjID, questionText, option1, option2, option3, option4, correctAnswer, correctExplanation, difficulty) VALUES
(3, 'What do plants need to grow?', 'Rocks', 'Water and sunlight', 'Plastic', 'Sand', 'Water and sunlight', 'Plants need water, sunlight, and soil to grow.', 'Easy'),
(3, 'Which part of the plant makes food?', 'Root', 'Stem', 'Leaf', 'Flower', 'Leaf', 'Leaves make food through photosynthesis.', 'Easy'),
(3, 'What do humans need to breathe?', 'Carbon dioxide', 'Oxygen', 'Water', 'Food', 'Oxygen', 'We breathe oxygen to live.', 'Easy'),
(3, 'Which organ pumps blood in the body?', 'Lungs', 'Heart', 'Stomach', 'Brain', 'Heart', 'The heart pumps blood through the body.', 'Easy'),
(3, 'Which sense helps you see?', 'Touch', 'Smell', 'Sight', 'Hearing', 'Sight', 'We see using our eyes.', 'Easy'),
(3, 'What gas do plants give off?', 'Oxygen', 'Carbon dioxide', 'Nitrogen', 'Helium', 'Oxygen', 'Plants release oxygen.', 'Medium'),
(3, 'What do you call baby frogs?', 'Fish', 'Tadpoles', 'Chicks', 'Pups', 'Tadpoles', 'Baby frogs are called tadpoles.', 'Easy'),
(3, 'The sun is a...', 'Planet', 'Star', 'Moon', 'Asteroid', 'Star', 'The sun is a star.', 'Easy'),
(3, 'What planet do we live on?', 'Mars', 'Earth', 'Venus', 'Jupiter', 'Earth', 'Humans live on Earth.', 'Easy'),
(3, 'What does a thermometer measure?', 'Speed', 'Temperature', 'Length', 'Weight', 'Temperature', 'Thermometers measure temperature.', 'Medium'),
(3, 'How many legs do insects have?', '4', '6', '8', '10', '6', 'Insects have six legs.', 'Medium'),
(3, 'Which part of the body helps you think?', 'Brain', 'Lungs', 'Stomach', 'Legs', 'Brain', 'The brain controls our thoughts.', 'Easy'),
(3, 'What covers and protects your body?', 'Skin', 'Bone', 'Hair', 'Blood', 'Skin', 'Skin covers and protects the body.', 'Easy'),
(3, 'What tool helps us see tiny things?', 'Microscope', 'Telescope', 'Binoculars', 'Glasses', 'Microscope', 'Microscopes let us see small objects.', 'Medium'),
(3, 'Which planet is closest to the sun?', 'Venus', 'Mercury', 'Earth', 'Mars', 'Mercury', 'Mercury is the closest planet to the Sun.', 'Medium'),
(3, 'What force pulls things to the ground?', 'Magnetism', 'Gravity', 'Friction', 'Wind', 'Gravity', 'Gravity pulls objects toward Earth.', 'Medium'),
(3, 'What part of the plant is underground?', 'Leaf', 'Stem', 'Root', 'Flower', 'Root', 'Roots grow under the ground.', 'Easy'),
(3, 'What helps fish breathe underwater?', 'Lungs', 'Gills', 'Fins', 'Scales', 'Gills', 'Fish use gills to breathe.', 'Medium'),
(3, 'What is the freezing point of water?', '0°C', '50°C', '100°C', '10°C', '0°C', 'Water freezes at 0°C.', 'Hard'),
(3, 'What shape is the Earth?', 'Flat', 'Square', 'Round', 'Triangle', 'Round', 'Earth is spherical in shape.', 'Easy');

-- GAME PROGRESS (2 logs)
INSERT INTO gameProgress (profileID, subjID, questionID, datePlayed, timeOn, timeOut, difficulty, level, points, playerAnswer, isCorrect) VALUES
(1, 1, 1, '2025-10-13', '10:00:00', '10:15:00', 'Easy', 1, 10, '5', 1),
(2, 2, 25, '2025-10-13', '10:20:00', '10:35:00', 'Easy', 1, 8, 'Bread', 1);
