{-- 
FLP 1st Project
Jordan Jarolim, xjarol03, FIT VUTBR
1. 4. 2017
project.hs
--}

import System.IO
import System.Environment
import Data.Map
import Data.Maybe
import Data.List as List
import Data.Ord
import Data.Function
import Data.List.Split
import System.Random
import Control.Monad (replicateM)
import System.IO.Unsafe



{--------------------MAIN AND PARAMETERS--------------------}
{-Main function to read parameters-}
main :: IO ()
main = do
    args <- getArgs
    let (fitness, dbName, param, fileName) = parseArgs args
    file <-
        if fileName == "stdin"
            then (getContents)
            else (readFile fileName)
    database <- (readFile dbName)

    -- delete whitespaces from input
    let fileWithoutSpaces = List.filter (\x -> notElem x (whiteSpaces)) file

    -- count occurences of letters
    let parsedInput = parseInput fileWithoutSpaces
    
    -- parseDB
    let parsedDB = divideByType $ parseDB $ List.lines database

    -- create list of symbols from db
    let symbols = intercalate "" (List.map (fst) (head parsedDB))
    
    -- generate first key
    let uncompleteFirstKey = generateFirstKey parsedInput

    -- fill missing letters in key
    let finalFirstKey = uncompleteFirstKey ++ (fillKey uncompleteFirstKey symbols)
    
    -- find all doubles in text
    let doubles = getXles fileWithoutSpaces 2
    
    -- take only interesting doubles
    let parsedDoubles = List.filter (\x -> length x == 2 ) $ List.take (List.length (parsedDB!!1)) $ parseXles doubles
    
    -- generate key from doubles based on pairs double <-> DB
    let doubleKey = getDoubleKey parsedDoubles (List.map (fst) (parsedDB!!1)) (List.intercalate "" (List.map (fst) (parsedDB!!0))) (List.length (parsedDoubles) - 1) (List.length (parsedDoubles) - 1) 
    
    -- filter multiple occurences
    let filteredDoubleKey = sortBy sortGT (nubBy (\x y -> (snd x) == (snd y) || (fst x) == (fst y)) doubleKey)

    -- convert key to string and fill gaps with '1'
    let finalDoubleKey = List.reverse $ List.map (fst) $ finalizeKey filteredDoubleKey 25

    -- find all triples in text
    let triples = getXles fileWithoutSpaces 3

    -- take only interesting triples
    let parsedTriples = List.filter (\x -> length x == 3 ) $ List.take (List.length (parsedDB!!2)) $ parseXles triples

    -- generate key from triples based on pairs triple <-> DB
    let tripleKey = getTripleKey parsedTriples (List.map (fst) (parsedDB!!2)) (List.intercalate "" (List.map (fst) (parsedDB!!0))) (List.length (parsedTriples) - 1) (List.length (parsedTriples) - 1) 

    -- filter multiple occurences
    let filteredTripleKey = sortBy sortGT (nubBy (\x y -> (snd x) == (snd y) || (fst x) == (fst y)) tripleKey)

    -- convert key to string and fill gaps with '1'
    let finalTripleKey = List.reverse $ List.map (fst) $ finalizeKey filteredTripleKey 25
    
    -- Combine all keys altogether
    let combinedKey = combineKeys finalFirstKey finalDoubleKey finalTripleKey [] 0

    -- decrypt text
    let decrypted = if fitness
            then decrypt fileWithoutSpaces parsedDB (tryKey finalFirstKey finalFirstKey 10000 parsedDB fileWithoutSpaces)
            else decrypt fileWithoutSpaces parsedDB combinedKey

    let output = if param
        then decrypted
        else combinedKey

    print output

    return ()


{--Parse arguments --}
parseArgs :: [[Char]] -> (Bool, [Char], Bool, [Char])
parseArgs ["-t", dbName, fileName] = (False, dbName, True, fileName)
parseArgs ["-k", dbName, fileName] = (False, dbName, False, fileName)
parseArgs ["-t", dbName] = (False, dbName, True, "stdin")
parseArgs ["-k", dbName] = (False, dbName, False, "stdin")

parseArgs ["-f", "-t", dbName, fileName] = (True, dbName, True, fileName)
parseArgs ["-f", "-k", dbName, fileName] = (True, dbName, False, fileName)
parseArgs ["-f", "-t", dbName] = (True, dbName, True, "stdin")
parseArgs ["-f", "-k", dbName] = (True, dbName, False, "stdin")
parseArgs _ = error "Spatne parametry."

{--------------------DB HANDLING--------------------}
{--Print DB --}
printDB::[[(String, Float)]] -> IO ()
printDB x = print x

{--Parse DB --}
parseDB::[String] -> [(String, Float)]
parseDB [] = []
parseDB (x:xs) = makeDBTouples(List.words (x)):parseDB xs

{--Make touples from DB information--}
makeDBTouples::[String] -> (String, Float)
makeDBTouples x = (List.head(x), read (List.last(x)) :: Float)

{--Divide into multiple lists by type (char, digram, trigram) and sort them by probability--}
divideByType::[(String, Float)] -> [[(String, Float)]]
divideByType [] = []
divideByType lst = [sortBy sortProb $ List.filter(\x -> (List.length $ fst x) == 1) lst, sortBy sortProb $  List.filter(\x -> (List.length $ fst x) == 2) lst, sortBy sortProb $  List.filter(\x -> (List.length $ fst x) == 3) lst]
sortProb (a1, b1) (a2, b2)
  | b1 < b2 = GT
  | b1 > b2 = LT
  | b1 == b2 = compare a1 a2

{--------------------INPUT HANDLING--------------------}
whiteSpaces = ['\n', '\t', '\r'] --Filtering whitespaces

{--Count occurences of chars in file (source: http://stackoverflow.com/questions/7108559/how-to-find-the-frequency-of-characters-in-a-string-in-haskell)--}
parseInput::String->[(Char, Int)]
parseInput input = List.filter (\x -> notElem (fst x) (whiteSpaces)) $ sortBy sortGT $ toList $ fromListWith (+) [(c, 1) | c <- input] --List.filter ((notElem ((fst,_) whiteSpaces)) ( ------ filter ((==1).fst) lst
sortGT (a1, b1) (a2, b2)
  | b1 < b2 = GT
  | b1 > b2 = LT
  | b1 == b2 = compare a1 a2

sortLT (a1, b1) (a2, b2)
  | b1 > b2 = GT
  | b1 < b2 = LT
  | b1 == b2 = compare a1 a2

{--------------------DECRYPTING--------------------}

{-- Generate first key --}
generateFirstKey::[(Char, Int)]->[Char]
generateFirstKey xs = List.map (fst) xs 

{-- Devrypt text by the final key--}
decrypt::String->[[(String, Float)]]->String->String
decrypt [] _ _ = []
decrypt input db key = List.intercalate "" $ List.map (\x -> (fst(List.head(db)!!(fromMaybe 0 $ elemIndex x key)))) input

{-- Get all doubles/triples from the text --}
getXles::String->Int->[String]
getXles decrypted n = Data.List.Split.chunksOf n decrypted ++ Data.List.Split.chunksOf n (List.tail decrypted) ++ Data.List.Split.chunksOf n (List.tail $ List.tail decrypted)

{-- Sort doubles/triples and edit them --}
parseXles::[String]->[String]
parseXles input = List.map fst $ sortBy sortGT $ toList $ fromListWith (+) [(c, 1) | c <- input]

{-- Add missing symbols from db into the first key --}
fillKey::[Char]->[Char]->[Char]
fillKey uncompleteFirstKey [] = []
fillKey uncompleteFirstKey (x:xs) = 
    if notElem x uncompleteFirstKey
    then x : fillKey uncompleteFirstKey xs
    else fillKey uncompleteFirstKey xs

{-- Fill missing chars in doube/triple keys --}
finalizeKey::[(Char, Int)]->Int->[(Char, Int)]
finalizeKey _ (-1) = []
finalizeKey (x:xs) n = 
    if (snd x) == n
        then x : finalizeKey xs (n-1)
        else ('1', 0) : finalizeKey (x:xs) (n-1)


{-- Generate double key --}
getDoubleKey::[String]->[String]->String->Int->Int->[(Char, Int)]
getDoubleKey _ _ _ _ (-1) = []
getDoubleKey doubles dbDoubles dbKey n counter = [((doubles!!(n-counter)!!0),(fromMaybe 0 $ elemIndex (dbDoubles!!(n-counter)!!0) dbKey)), ((doubles!!(n-counter)!!1),(fromMaybe 0 $ elemIndex (dbDoubles!!(n-counter)!!1) dbKey))] ++ getDoubleKey doubles dbDoubles dbKey n (counter-1)

{-- Generate triple key--}
getTripleKey::[String]->[String]->String->Int->Int->[(Char, Int)]
getTripleKey _ _ _ _ (-1) = []
getTripleKey triples dbTriples dbKey n counter = [((triples!!(n-counter)!!0),(fromMaybe 0 $ elemIndex (dbTriples!!(n-counter)!!0) dbKey)), ((triples!!(n-counter)!!1),(fromMaybe 0 $ elemIndex (dbTriples!!(n-counter)!!1) dbKey)), ((triples!!(n-counter)!!2),(fromMaybe 0 $ elemIndex (dbTriples!!(n-counter)!!2) dbKey))] ++ getTripleKey triples dbTriples dbKey n (counter-1)

{-- Combine keys together --}
combineKeys::String->String->String->String->Int->String
combineKeys simple double triple final n
    | n > 25 = final
    | n <= 25 =
        if (simple!!n == double!!n && double!!n == triple!!n) -- 111 || 000
            then combineKeys simple double triple (final ++ [(simple!!n)]) (n + 1)

        else if (simple!!n == double!!n && double!!n /= triple!!n) -- 110 || 001
            then combineKeys simple double triple (final ++ [(simple!!n)]) (n + 1)

        else if (simple!!n == triple!!n && double!!n /= triple!!n) -- 101 || 010
            then combineKeys simple double triple (final ++ [(simple!!n)]) (n + 1)

        else -- 011 || 100
            if notElem (triple!!n) final && (triple!!n) /= '1'
                then combineKeys simple double triple (final ++ [(triple!!n)]) (n + 1)
            else if notElem (double!!n) final && (double!!n) /= '1'
                then combineKeys simple double triple (final ++ [(double!!n)]) (n + 1)
            else
                combineKeys simple double triple (final ++ [(simple!!n)]) (n + 1)



{--------------------Old implementation with fitness function--------------------}

{--http://stackoverflow.com/questions/30551033/swap-two-elements-in-a-list-by-its-indices--}
swap::String->Int->Int->String
swap list a b 
    | b > a = list1 ++ [list !! b] ++ list2 ++ [list !! a] ++ list3
    | a > b = list4 ++ [list !! a] ++ list5 ++ [list !! b] ++ list6
    | a == b = list
        where   list1 = List.take a list;
                list2 = List.drop (succ a) (List.take b list);
                list3 = List.drop (succ b) list
                list4 = List.take b list;
                list5 = List.drop (succ b) (List.take a list);
                list6 = List.drop (succ a) list

isDictTriple::String->[String]->[[(String, Float)]]->Maybe Int
isDictTriple x triples db = elemIndex x $ List.map (fst) $ List.last db

countFitness::[String]->[[(String, Float)]]->Float
countFitness triples db = List.foldl (\acc x -> acc + log x) 0 $ List.map (\x -> snd(List.last(db)!!x)) $ List.filter (/=(-1)) $ List.map (\x -> fromMaybe (-1) $ isDictTriple x triples db) triples

{--https://hackage.haskell.org/package/random-1.1/docs/System-Random.html--}
rollDice::Int -> Int -> IO Int
rollDice n m = do 
    k <- getStdRandom (randomR (n,m))
    return (k)

tryKey::String->String->Int->[[(String, Float)]]->String->String
tryKey oldKey newKey iterator parsedDB input = 
    if (iterator > 0)
    then
        if ((countFitness (getXles (decrypt input parsedDB oldKey) 3) parsedDB) >= (countFitness ( getXles ( decrypt input parsedDB newKey) 3) parsedDB))
        then tryKey oldKey ( swap oldKey (unsafePerformIO (rollDice 0 $ (List.length oldKey - 1))) (unsafePerformIO (rollDice 0 $ (List.length oldKey - 1)))) (iterator - 1) parsedDB input 
        else tryKey newKey ( swap newKey (unsafePerformIO (rollDice 0 $ (List.length newKey - 1))) (unsafePerformIO (rollDice 0 $ (List.length newKey - 1)))) 10000 parsedDB input 
    else
        oldKey

