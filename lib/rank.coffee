
module.exports = 

	getRank: (rating) ->
		if rating.rating? then rating = rating.rating
		if rating < 100
			rank = Math.floor(rating / 10)
			return -(30-rank)
		else if rating < 2700
			rank = Math.floor(rating / 100)
			if rank < 20 then return -(20 - rank + 1)
			if rank < 27 then return (rank - 20)
		else
			rank = (rating - 2700) / 30
			return Math.floor(rank+7)

	getRankString: (rating) ->
		if rating.rating? then rating = rating.rating
		if rating < 100
			rank = Math.floor(rating / 10)
			return (30-rank)+'K' 
		else if rating < 2700
			rank = Math.floor(rating / 100)
			if rank < 20 then return (20 - rank + 1)+'K'
			if rank < 27 then return (rank - 20)+'D'
		else
			rank = (rating - 2700) / 30
			return Math.floor(rank+1)+'P'
