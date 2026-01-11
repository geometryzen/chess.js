{{
  function rootNode(comment) {
  	return comment !== null ? { comment, nags: [], variations: [] } : { nags: [], variations: []}
  }

  function node(move, suffixAnnotation, nags, comment, variations) {
  	const node = { move, nags, variations }

    if (suffixAnnotation) {
    	node.suffixAnnotation = suffixAnnotation
    }

    if (comment !== null) {
        if (typeof comment == 'string') {
            // A comment that came from restOfLineComment.
    	    node.comment = comment
        }
        else if (Array.isArray(comment)) {
            const cs = comment;
            cs.forEach(function(c, index) {
                if (c.includes("[%")) {
                    // It is a metadata comment.
                }
                else {
                    node.comment = c
                }
            });
        }
    }

    return node
  }

  function lineToTree(...nodes) {
  	const [root, ...rest] = nodes;

    let parent = root

    for (const child of rest) {
    	if (child !== null) {
        	parent.variations = [child, ...child.variations]
            child.variations = []
            parent = child
        }
    }

  	return root
  }

  function pgn(headers, game) {
  	if (game.marker && game.marker.comment) {
    	let node = game.root
        while (true) {
        	const next = node.variations[0]
            if (!next) {
            	node.comment = game.marker.comment
            	break
            }
            node = next
        }
    }

  	return {
    	headers,
        root: game.root,
        result: (game.marker && game.marker.result) ?? undefined
    }
  }
}}

pgn
    = headers:tagPairSection game:moveTextSection { return pgn(headers, game) }

tagPairSection
 	= tagPairs:tagPair* _ { return Object.fromEntries(tagPairs) }

tagPair "tag pair"
	= _ '[' _ tagName:tagName _ '"' tagValue:tagValue '"' _ ']' { return [tagName, tagValue] }

tagName "tag name"
	= $[a-zA-Z]+

tagValue "tag value"
	= $[^"]*

moveTextSection
	= root:line _ marker:gameTerminationMarker? _ { return { root, marker} }

line
	= comment:comment? moves:move* { return lineToTree(rootNode(comment), ...moves.flat()) }

move
	= _ moveNumber? _ san:san suffixAnnotation:suffixAnnotation? nags:nag*  _ comment:moveComment? variations:variation* { return node(san, suffixAnnotation, nags, comment, variations) }

moveNumber "move number"
    = [0-9]*'.' _ [.]*

san "standard algebraic notation"
	= $(("O-O-O" / "O-O" / "0-0-0" / "0-0" / [a-zA-Z][a-zA-Z1-8-=]+) [+#]?)

suffixAnnotation "suffix annotation"
	= $[!?] |1..2|
      
nag "NAG"
	= _ '$' nag:$[0-9]+ { return parseInt(nag, 10) }

comment
	= braceComment / restOfLineComment

moveComment
	= braceComment+ / restOfLineComment

braceComment "brace comment"
	= _ '{' comment:$[^}]* '}' { return comment.replace(/[\r\n]+/g, " ") }

restOfLineComment "rest of line comment"
	= ';' comment:$[^\r\n]* { return comment.trim() }

variation "variation"
    = _ '(' line:line _ ')' { return line }

gameTerminationMarker "game termination marker"
	= result:('1-0' / '0-1' / '1/2-1/2' / '*') _ comment:comment? { return { result, comment } }

_ "whitespace"
  = [\x20\t\r\n]*
