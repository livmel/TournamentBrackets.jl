module TournamentBrackets

export SimpleSeededBracket

import Base: push!

using DataStructures

abstract type SimpleBracketNode end

mutable struct SimpleMatch <: SimpleBracketNode
    lo::SimpleBracketNode
    hi::SimpleBracketNode
end

struct SimpleTeam <: SimpleBracketNode
    seed::Int
end
# escape_string(io, team.name)

struct SimpleBye <: SimpleBracketNode end

struct SimpleSeededBracket
    root::SimpleMatch
end

function SimpleSeededBracket(n::Integer)
    if n ≤ 0
        error("non-positive bracket size")
    end
    brac = SimpleSeededBracket(SimpleMatch(SimpleTeam(1), SimpleBye()))
    byes = PriorityQueue(Base.Order.Reverse)
    enqueue!(byes, brac.root, brac.root.lo.seed)
    round = SimpleMatch[]
    for s = 2:n
        if isempty(byes)
            for match ∈ round
                match.lo = SimpleMatch(match.lo, SimpleBye())
                enqueue!(byes, match.lo, match.lo.lo.seed)
                match.hi = SimpleMatch(match.hi, SimpleBye())
                enqueue!(byes, match.hi, match.hi.lo.seed)
            end
            empty!(round)
        end
        match = dequeue!(byes)
        match.hi = SimpleTeam(s)
        push!(round, match)
    end
    return brac
end

end
