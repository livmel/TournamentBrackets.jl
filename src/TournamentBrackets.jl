module TournamentBrackets

export AbstractBracket, SimpleSeededBracket

import Base: show#, push!

using DataStructures
using Luxor

abstract type AbstractBracket end

show(io::IO, m::MIME"image/png", brac::AbstractBracket) = show(io, m, draw(brac, :png))
show(io::IO, m::MIME"image/svg+xml", brac::AbstractBracket) = show(io, m, draw(brac, :svg))

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

struct SimpleSeededBracket <: AbstractBracket
    root::SimpleMatch
    depth::Int
end

function SimpleSeededBracket(n::Integer)
    if n ≤ 0
        error("non-positive bracket size")
    end
    root = SimpleMatch(SimpleTeam(1), SimpleBye())
    depth = 1
    byes = PriorityQueue(Base.Order.Reverse)
    enqueue!(byes, root, root.lo.seed)
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
            depth += 1
        end
        match = dequeue!(byes)
        match.hi = SimpleTeam(s)
        push!(round, match)
    end
    return SimpleSeededBracket(root, depth)
end

function draw(brac::SimpleSeededBracket, file)
    # params
    pad_h = 50
    pad_v = 50
    textheight = 50
    textgap = 50
    textwidth = 200
    textmargin = 5
    # calcs
    v = textheight + textgap
    w = textwidth * (brac.depth + 1) + 2pad_h
    h = v * (2 * 2^brac.depth - 1) + 2pad_v
    # draw
    d = Drawing(w, h, file)
    origin(Point(pad_h, pad_v))
    scale(textwidth, v)
    draw(brac.root, Point(brac.depth + 1, 2^brac.depth), brac.depth, (; pad_h, pad_v, textheight, textgap, textwidth, textmargin))
    finish()
    return d
end

function draw(node::SimpleMatch, P::Point, depth::Int, params::NamedTuple)
    d = 2^(depth - 1)
    line(P + Point(0, 0), P + Point(-1, 0), action = :stroke)
    line(P + Point(-1, -d), P + Point(-1, d), action = :stroke)
    draw(node.lo, P + Point(-1, -d), depth - 1, params)
    draw(node.hi, P + Point(-1, d), depth - 1, params)
end

function draw(::SimpleBye, ::Point, ::Int, ::NamedTuple) end

function draw(team::SimpleTeam, P::Point, ::Int, params::NamedTuple)
    line(P + Point(-1, 0), P + Point(0, 0), action = :stroke)
    gsave()
    P *= getscale()
    origin(Point(params.pad_h, params.pad_v))
    P1 = P + Point(-params.textwidth, -params.textheight)
    P2 = P + Point(0, 0)
    textfit(string(team.seed), BoundingBox(box(P1, P2)), horizontalmargin = params.textmargin)
    grestore()
end

end
