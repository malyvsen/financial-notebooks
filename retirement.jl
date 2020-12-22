### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ c27386f4-4393-11eb-1fb2-43bf6a1d7de0
begin
	using Distributions
	using Statistics
	using StatsPlots
	gr(fmt=:png) # forces sensible plot size
	using PlutoUI
	md"Imports"
end

# ╔═╡ 2c367f68-4394-11eb-1098-23e08449a7dd
md"# Saving for retirement
...is mostly about tax exemption."

# ╔═╡ 4dcb250c-4394-11eb-2f24-9f3f5aec7f10
md"We're talking about $(@bind num_people NumberField(1:5, default=2)) people saving for retirement together."

# ╔═╡ 0dda613c-4395-11eb-2c8e-ff08529d84e8
md"They are planning to retire in $(@bind years_to_retirement NumberField(0:50, default=20)) years, and they're expecting to live another $(@bind years_after_retirement NumberField(0:50, default=20)) after retiring."

# ╔═╡ 5e700f84-4395-11eb-0728-f9c7a615f399
md"They currently have PLN $(@bind initial_investment NumberField(0:1e7, default=Int(200e3))) they are willing to invest."

# ╔═╡ c2ed1baa-4395-11eb-2391-b9155da66af2
md"Their total monthly revenue is PLN $(@bind monthly_revenue NumberField(0:1e5, default=Int(10e3))), of which they spend PLN $(@bind monthly_cost NumberField(0:1e5, default=Int(5e3))) in the average month."

# ╔═╡ c4470892-4397-11eb-305d-c3fe29382c16
md"""
## Economy assumptions
"""

# ╔═╡ cfc9b566-4397-11eb-231c-37c0da3c3da2
md"We assume a yearly inflation rate of $(@bind yearly_inflation_percent NumberField(0:0.1:10, default=2.5))%."

# ╔═╡ 7711e8d8-43d0-11eb-01fd-8faca7a26c5d
md"Market returns will be, on average, $(@bind market_real_return_percent NumberField(0:0.1:100, default=4.3))% per year in real terms, with a yearly standard deviation of $(@bind market_stddev_percent NumberField(0:0.1:100, default=15))%."

# ╔═╡ fb8df1d8-43d0-11eb-1cd0-655f5240b570
md"""
Government bonds, on the other hand, deliver a $(@bind bond_premium_percent NumberField(0:0.1:10, default=1))% premium above inflation.
"""

# ╔═╡ 8cfda320-43e5-11eb-1d02-d5d21784a008
begin
	yearly_bond_returns = 1 + yearly_inflation_percent / 100 + bond_premium_percent / 100
	md"This means that keeping your money in bonds multiplies its nominal value by $(yearly_bond_returns) every year."
end

# ╔═╡ 2896e0a6-4398-11eb-07dd-e5c27ac014a7
md"Personal income tax is $(@bind personal_income_tax_percent NumberField(0:0.1:100, default=17))%, and capital gains tax is $(@bind capital_gains_tax_percent NumberField(0:0.1:100, default=19))%."

# ╔═╡ 3a29e51c-4397-11eb-35e6-7bef72a87db9
md"""
## Investment strategy
"""

# ╔═╡ 3ca08438-43e0-11eb-004f-17a75401c481
md"Asset allocation of initial investment: `bonds` $(@bind initial_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFs`"

# ╔═╡ 6879734c-4397-11eb-20b1-c521c4d1dbbf
md"""
### IKE
An IKE is a savings account which lets you not pay capital gains tax if you withdraw your funds above the age of 60. The maximum yearly amount that can be transferred to a single IKE is PLN $(@bind ike_yearly_limit NumberField(0:1e5, default=15681)), but our savers can have one IKE each.
"""

# ╔═╡ 2fee2ecc-43de-11eb-0168-2943ab290ff0
begin
	ike_cumulative_yearly_limit = ike_yearly_limit * num_people
	md"""
In total, our savers put PLN $(@bind ike_yearly NumberField(0:0.01:ike_cumulative_yearly_limit, default=ike_cumulative_yearly_limit)) in their IKEs every year, out of the maximum legal value of PLN $ike_cumulative_yearly_limit.
	"""
end

# ╔═╡ ea083430-43df-11eb-10a8-0d3e898644f8
md"Asset allocation within the IKEs: `bonds` $(@bind ike_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFs`"

# ╔═╡ 9eb214ce-43dc-11eb-29a4-2712e312f969
md"""
### IKZE
And IKZE is a savings account which lets you subtract the amount paid to it in a given year from that year's income for tax purposes. Withdrawing from an IKZE is possible after the age of 65 at a tax rate of $(@bind ikze_tax_percent NumberField(0:0.1:100, default=10))%. The maximum yearly amount that can be transferred to a single IKZE is PLN $(@bind ikze_yearly_limit NumberField(0:1e5, default=6272.4)), but our savers can have one IKZE each.
"""

# ╔═╡ b3a46636-43df-11eb-233b-3d178928ffe6
begin
	ikze_cumulative_yearly_limit = ikze_yearly_limit * num_people
	md"""
In total, our savers put PLN $(@bind ikze_yearly NumberField(0:0.01:ikze_cumulative_yearly_limit, default=Int(5e3))) in their IKZEs every year, out of the maximum legal value of PLN $ikze_cumulative_yearly_limit.
	"""
end

# ╔═╡ 16ba6086-43e0-11eb-280b-232a403709bb
md"Asset allocation within the IKZEs: `bonds` $(@bind ikze_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFs`"

# ╔═╡ 32f6e32a-43e3-11eb-14e5-c9a22c45ca46
md"## Results"

# ╔═╡ 27cd099c-4394-11eb-0cc0-eb21f9c082c5
md"## Technicalities"

# ╔═╡ 63a9a050-43e5-11eb-18d3-b9a01b3a7b60
num_samples = 4096

# ╔═╡ 128bb4be-43ee-11eb-174c-bda51ab6dd38
display_money(money) =
if money < 1e3
	"$(Int(round(money)))"
elseif money < 1e5
	"$(round(money / 1e3, digits=1))K"
elseif money < 1e6
	"$(Int(round(money / 1e3)))K"
elseif money < 1e8
	"$(round(money / 1e6, digits=1))M"
else
	"$(Int(round(money / 1e6)))M"
end

# ╔═╡ 64441bb6-4396-11eb-34e7-49024ebb7bb1
if monthly_cost > monthly_revenue
	md"Monthly costs surpass monthly revenue. I hope it's not really so?"
else
	yearly_revenue = monthly_revenue * 12
	yearly_cost = monthly_cost * 12
	md"This means they spend $(Int(round(monthly_cost / monthly_revenue * 100)))% of their income each month. These figures add up to a yearly revenue of PLN $(display_money(yearly_revenue)) and a yearly spending of PLN $(display_money(yearly_cost))."
end

# ╔═╡ 8c8a52d2-4398-11eb-0549-493b3968b3b7
begin
	inflation_at_retirement = (1 + yearly_inflation_percent / 100) .^ years_to_retirement
	md"This means that in $(years_to_retirement) years our new retirees will need to be spending PLN $(display_money(monthly_cost * inflation_at_retirement)) to sustain their current standard of living, because PLN 1 will be worth as much as PLN $(round(1 / inflation_at_retirement, digits=2)) is now."
end

# ╔═╡ bd353520-4396-11eb-1250-2f5bbbca4582
begin
	current_yearly_tax = yearly_revenue * personal_income_tax_percent / 100
	current_yearly_profit = yearly_revenue - yearly_cost - current_yearly_tax
	md"This means our savers pay PLN $(display_money(current_yearly_tax)) in taxes every year, leaving PLN $(display_money(current_yearly_profit)) in savings."
end

# ╔═╡ 002bc00c-43e1-11eb-0dad-c9e4ca4ca2f5
begin
	post_ikze_yearly_tax = (yearly_revenue - ikze_yearly) * personal_income_tax_percent / 100
	post_ikze_yearly_profit = yearly_revenue - yearly_cost - post_ikze_yearly_tax
	md"This reduces their tax by PLN $(display_money(current_yearly_tax - post_ikze_yearly_tax)), down to PLN $(display_money(post_ikze_yearly_tax))."
end

# ╔═╡ eaa4fd02-43e0-11eb-1fe6-03f1d6b2bffb
begin
	yearly_unused = post_ikze_yearly_profit - ike_yearly - ikze_yearly
	if yearly_unused < 0
		md"Allocation to IKE and IKZE combined exceeds yearly profit of PLN $(Int(round(post_ikze_yearly_profit))). Allocate PLN $(Int(round(-yearly_unused))) less to IKE and IKZE."
	else
		md"The IKE and IKZE allocations leave PLN $(Int(round(yearly_unused))) per year on the table to cover unforseen expenses."
	end
end

# ╔═╡ cc733592-43ea-11eb-1680-674be3b4f526
function apply_capital_gains_tax(; incomes, samples)
	taxable = max.(sum(incomes), samples) .- sum(incomes)
	return samples .- taxable * capital_gains_tax_percent / 100
end

# ╔═╡ 2e5efc8e-43e9-11eb-2085-992b2bb0e415
function sample_money(; incomes, return_samples)
	return_cumprod = cumprod(return_samples, dims=2)
	income_contributions = reverse(return_cumprod, dims=2) .* reshape(incomes, (1, size(incomes)...))
	return sum(income_contributions, dims=2)
end

# ╔═╡ 2bf4fa46-43e6-11eb-3062-af36f804987a
function sample_bonds(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=fill(yearly_bond_returns, (num_samples, length(incomes)))
	)
end

# ╔═╡ 4be44610-43e9-11eb-3826-fd0f912f140f
sample_money(incomes=[1, 2, 3], return_samples=[[1 1 1]; [2 2 2]])

# ╔═╡ cdefcc0c-43e3-11eb-05f7-a3ac48051b3c
function mle_returns_distribution(samples)
	eps = 1e-2
	if std(samples) < eps
		Uniform(mean(samples) - eps, mean(samples) + eps)
	else
		truncated(fit_mle(Laplace, samples), 0, 2 * mean(samples))
	end
end

# ╔═╡ 5340c3b4-43eb-11eb-0ef7-395556e136df
function wealth_plot(samples; title="Distribution of wealth at retirement")
	wealth_distribution = mle_returns_distribution(samples)
	plot(title=title, xformatter=display_money)
	plot!(wealth_distribution / inflation_at_retirement, func=cdf, label="Real")
	plot!(wealth_distribution, func=cdf, label="Nominal")
end

# ╔═╡ 2ca0bbda-43d8-11eb-18c3-93c9a3b46e70
function returns_power(laplace, exponent)
	samples = rand(laplace, (num_samples, exponent))
	products = prod(samples, dims=2)
	return mle_returns_distribution(products)
end

# ╔═╡ d32af702-43d7-11eb-0c46-2b102654e254
returns_distribution(mean, stddev) = truncated(Laplace(mean, stddev / sqrt(2)), 0, 2 * mean)

# ╔═╡ 863a0768-43d1-11eb-223d-e5fcd18b9417
begin
	market_multiplier_yearly = (1 + market_real_return_percent / 100) * (1 + yearly_inflation_percent / 100)
	market_yearly_distribution = returns_distribution(market_multiplier_yearly, market_stddev_percent / 100)
	market_to_retirement_distribution = returns_power(market_yearly_distribution, years_to_retirement)
	plot(title="Market return CDFs")
	plot!(market_yearly_distribution, func=cdf, label="Yearly")
	plot!(market_to_retirement_distribution, func=cdf, label="Until retirement")
end

# ╔═╡ 6663f948-43e6-11eb-3988-61c42e69613a
function sample_etfs(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=rand(market_yearly_distribution, (num_samples, length(incomes)))
	)
end

# ╔═╡ 5bb7fcfc-43e5-11eb-0f55-c9bdd6557449
begin
	initial_incomes = zeros(years_to_retirement)
	initial_incomes[1] = initial_investment
	initial_samples = apply_capital_gains_tax(
		incomes=initial_incomes,
		samples=(
			(1 - initial_etf_allocation) .* sample_bonds(initial_incomes)
			.+ initial_etf_allocation .* sample_etfs(initial_incomes)
		)
	)
	wealth_plot(initial_samples, title="Initial investment value at retirement")
end

# ╔═╡ b4308f9a-43ef-11eb-244f-75e1e3b1851a
begin
	ike_incomes = fill(ike_yearly, years_to_retirement)
	ike_samples = (
		(1 - ike_etf_allocation) .* sample_bonds(ike_incomes)
		.+ ike_etf_allocation .* sample_etfs(ike_incomes)
	)
	wealth_plot(ike_samples, title="IKE value at retirement")
end

# ╔═╡ 5816674a-43f0-11eb-34f6-09a53fc611fd
begin
	ikze_incomes = fill(ikze_yearly, years_to_retirement)
	ikze_samples = (
		(1 - ikze_etf_allocation) .* sample_bonds(ikze_incomes)
		.+ ikze_etf_allocation .* sample_etfs(ikze_incomes)
	) .* (1 - ikze_tax_percent / 100)
	wealth_plot(ikze_samples, title="IKZE value at retirement")
end

# ╔═╡ 48ed7d74-43e3-11eb-0976-c52b73747a52
begin
	overall_samples = initial_samples + ike_samples + ikze_samples
	wealth_plot(overall_samples)
end

# ╔═╡ 28920e72-4448-11eb-31d8-a793fe2aaccd
begin
	overall_monthly_retirement_samples = overall_samples / years_after_retirement / 12
	wealth_plot(overall_monthly_retirement_samples, title="Distribution of extra monthly money in retirement")
end

# ╔═╡ Cell order:
# ╟─2c367f68-4394-11eb-1098-23e08449a7dd
# ╟─4dcb250c-4394-11eb-2f24-9f3f5aec7f10
# ╟─0dda613c-4395-11eb-2c8e-ff08529d84e8
# ╟─5e700f84-4395-11eb-0728-f9c7a615f399
# ╟─c2ed1baa-4395-11eb-2391-b9155da66af2
# ╟─64441bb6-4396-11eb-34e7-49024ebb7bb1
# ╟─c4470892-4397-11eb-305d-c3fe29382c16
# ╟─cfc9b566-4397-11eb-231c-37c0da3c3da2
# ╟─8c8a52d2-4398-11eb-0549-493b3968b3b7
# ╟─7711e8d8-43d0-11eb-01fd-8faca7a26c5d
# ╟─863a0768-43d1-11eb-223d-e5fcd18b9417
# ╟─fb8df1d8-43d0-11eb-1cd0-655f5240b570
# ╟─8cfda320-43e5-11eb-1d02-d5d21784a008
# ╟─2896e0a6-4398-11eb-07dd-e5c27ac014a7
# ╟─bd353520-4396-11eb-1250-2f5bbbca4582
# ╟─3a29e51c-4397-11eb-35e6-7bef72a87db9
# ╟─3ca08438-43e0-11eb-004f-17a75401c481
# ╟─5bb7fcfc-43e5-11eb-0f55-c9bdd6557449
# ╟─6879734c-4397-11eb-20b1-c521c4d1dbbf
# ╟─2fee2ecc-43de-11eb-0168-2943ab290ff0
# ╟─ea083430-43df-11eb-10a8-0d3e898644f8
# ╟─b4308f9a-43ef-11eb-244f-75e1e3b1851a
# ╟─9eb214ce-43dc-11eb-29a4-2712e312f969
# ╟─b3a46636-43df-11eb-233b-3d178928ffe6
# ╟─002bc00c-43e1-11eb-0dad-c9e4ca4ca2f5
# ╟─16ba6086-43e0-11eb-280b-232a403709bb
# ╟─5816674a-43f0-11eb-34f6-09a53fc611fd
# ╟─eaa4fd02-43e0-11eb-1fe6-03f1d6b2bffb
# ╟─32f6e32a-43e3-11eb-14e5-c9a22c45ca46
# ╟─48ed7d74-43e3-11eb-0976-c52b73747a52
# ╟─28920e72-4448-11eb-31d8-a793fe2aaccd
# ╟─27cd099c-4394-11eb-0cc0-eb21f9c082c5
# ╟─63a9a050-43e5-11eb-18d3-b9a01b3a7b60
# ╟─5340c3b4-43eb-11eb-0ef7-395556e136df
# ╟─128bb4be-43ee-11eb-174c-bda51ab6dd38
# ╟─cc733592-43ea-11eb-1680-674be3b4f526
# ╟─2bf4fa46-43e6-11eb-3062-af36f804987a
# ╟─6663f948-43e6-11eb-3988-61c42e69613a
# ╠═4be44610-43e9-11eb-3826-fd0f912f140f
# ╟─2e5efc8e-43e9-11eb-2085-992b2bb0e415
# ╟─2ca0bbda-43d8-11eb-18c3-93c9a3b46e70
# ╟─cdefcc0c-43e3-11eb-05f7-a3ac48051b3c
# ╟─d32af702-43d7-11eb-0c46-2b102654e254
# ╟─c27386f4-4393-11eb-1fb2-43bf6a1d7de0
