public class NaiveBayesClassifier {
    public typealias Category = String
    
    private let tokenizer: String -> [String]
    
    private var categoryOccurrences: [Category: Int] = [:]
    private var tokenOccurrences: [String: [Category: Int]] = [:]
    private var trainingCount = 0
    private var tokenCount = 0
    
    private let smoothingParameter = 1.0
    
    public init(tokenizer: (String -> [String])) {
        self.tokenizer = tokenizer
    }
    
    // MARK: - Training
    
    public func trainWithText(text: String, category: Category) {
        trainWithTokens(tokenizer(text), category: category)
    }
    
    public func trainWithTokens(tokens: [String], category: Category) {
        let tokens = Set(tokens)
        for token in tokens {
            incrementToken(token, category: category)
        }
        incrementCategory(category)
        trainingCount++
    }
    
    // MARK: - Classifying
    
    public func classifyText(text: String) -> Category? {
        return classifyTokens(tokenizer(text))
    }
    
    public func classifyTokens(tokens: [String]) -> Category? {
        // Compute argmax_cat [log(P(C=cat)) + sum_token(log(P(W=token|C=cat)))]
        var maxCategory: Category?
        var maxCategoryScore = -Double.infinity
        for (category, _) in categoryOccurrences {
            let pCategory = P(category)
            let score = tokens.reduce(log(pCategory)) { (total, token) in
                // P(W=token|C=cat) = P(C=cat, W=token) / P(C=cat)
                total + log((P(category, token) + smoothingParameter) / (pCategory + smoothingParameter * Double(tokenCount)))
            }
            if score > maxCategoryScore {
                maxCategory = category
                maxCategoryScore = score
            }
        }
        return maxCategory
    }
    
    // MARK: - Probabilites
    
    private func P(category: Category, _ token: String) -> Double {
        return Double(tokenOccurrences[token]?[category] ?? 0) / Double(trainingCount)
    }
    
    private func P(category: Category) -> Double {
        return Double(totalOccurrencesOfCategory(category)) / Double(trainingCount)
    }
    
    // MARK: - Counting
    
    private func incrementToken(token: String, category: Category) {
        if tokenOccurrences[token] == nil {
            tokenCount++
            tokenOccurrences[token] = [:]
        }
        
        // Force unwrap to crash instead of providing faulty results.
        let count = tokenOccurrences[token]![category] ?? 0
        tokenOccurrences[token]![category] = count + 1
    }
    
    private func incrementCategory(category: Category) {
        categoryOccurrences[category] = totalOccurrencesOfCategory(category) + 1
    }
    
    private func totalOccurrencesOfToken(token: String) -> Int {
        if let occurrences = tokenOccurrences[token] {
            return reduce(occurrences.values, 0, +)
        }
        return 0
    }
    
    private func totalOccurrencesOfCategory(category: Category) -> Int {
        return categoryOccurrences[category] ?? 0
    }
}