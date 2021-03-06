%% likelihoodStep2.m
% We now construct the likelihood contributions that result from the number
% of firms evolving from $n$ to $n'$. Recall that we obtain cost-shock
% thresholds for entry and survival, defined by $\overline w_{E}(n,c)
% \equiv \log v_{S}(n,c) - \log\left(1 + \varphi\right)$ and
% $\overline w_{S}(n,c)\equiv \log v_{S}(n,c)$. We consider five mutually
% exclusive cases.
%
% \begin{itemize}
% \item \textbf{Case I: $\mathbf{n'>n}$.}
% If the number of firms increases from $n$ to $n'$, then it must be
% profitable for the $n'$th firm to enter, but not for the $(n'+1)$th:
% $\overline w_{E}(n'+1,c)\leq w  < \overline w_{E}(n',c)$. The probability
% of this event is
% \begin{equation} \label{app:eq:llhcontr1}
% G_W\left[\overline w_{E}(n',c)\right]-G_W\left[\overline w_{E}(n'+1,c)\right].
% \end{equation}
%
% \item \textbf{Case II: $\mathbf{0<n'<n}$.}
% If the number of firms decreases from $n$ to $n'$, with $0<n'<n$, then
% the realization of $W$ must be such that firms exit with probability
% $a_{S}(n,c,w)\in(0,1)$. Thus, the cost shock must be high enough so that
% $n$ firms cannot survive profitably, $w\geq\overline w_{S}(n,c)$, but low
% enough for a monopolist to survive profitably, $w < \overline
% w_{S}(1,c)$. Given such value $w$, $N'$ is binomially distributed with
% success probability $a_{S}(n,c,w)$ and population size $n$. Hence, the
% probability of observing a transition from $n$ to $n'$ with $0<n'<n$
% equals
% \begin{equation} \label{app:eq:llhcontr2}
% \int_{\overline w_{S}(n,c)}^{\overline w_{S}(1,c)} {n \choose n'} a_{S}(n,c,w)^{n'}\left[1-a_{S}(n,c,w)\right]^{n-n'} g_W(w)dw,
% \end{equation}
%
% where $g_W$ is the density of $G_W$. The integrand in
% (\ref{app:eq:llhcontr2}) involves the mixing probabilities
% $a_{S}(n,c,w)$. We discuss how we compute this integral in detail below.
%
% \item \textbf{Case III: $\mathbf{n'=0, n>0}$.}
% All firms exiting can be the result of two events. First, it is not
% profitable for even a single firm to continue, $w \geq \overline
% w_{S}(1,c)$. Second, it is profitable for some but not all firms to
% continue, $\overline w_{S}(n,c) \leq w <\overline w_{S}(1,c)$, firms exit
% with probability $a_S(n,c)\in(0,1)$ as in Case II, and by chance none of
% the $n$ firms survives. The probability of these events is
% \begin{equation}
% \label{app:eq:llhcontr3}
% 1-G_W\left[\overline w_{S}(1,c)\right] +\int_{\overline w_{S}(n,c)}^{\overline w_{S}(1,c)}\left[1-a_{S}(n,c,w)\right]^{n} g_W(w)dw.
% \end{equation}
%
% \item \textbf{Case IV: $\mathbf{n'=0, n=0}$.}
% In this case, the market is populated by zero firms and it is not
% profitable for a monopolist to enter. The probability of this event is given
% by
% \begin{equation}
% \label{app:eq:llhcontr4}
% 1-G_W\left[\overline w_{E}(1,c)\right].
% \end{equation}
%
% \item \textbf{Case V: $\mathbf{n' = n > 0}$.}
% If there is neither entry nor exit, then either no firm finds it
% profitable to enter and all $n$ incumbents find it profitable to stay,
% $\overline w_{E}(n+1,c) \leq w <\overline w_{S}(n,c),$ or the $n$
% incumbents mix as in Cases II and III, but by chance end up all staying.
% The probability of these events is
% \begin{equation} \label{app:eq:llhcontr5}
% G_W\left[\overline w_{S}(n,c)\right]-G_W\left[\overline w_{E}(n+1,c)\right] + \int_{\overline w_{S}(n,c)}^{\overline w_{S}(1,c)} a_{S}(n,c,w)^{n} g_W(w)dw.
% \end{equation}
% \end{itemize}
% We compute the likelihood using the function |likelihoodStep2| that
% requires as inputs the structures |Data|, |Settings|, and |Param|, and
% the vector |estimates| as inputs. It returns the scalar valued negative
% log-likelihood function |ll| and a column vector of length $\check r
% \times (\check t - 1)$ containing the market-time-specific likelihood
% contributions,
% |likeCont|.

function [ll, likeCont] = likelihoodStep2(Data, Settings, Param, estimates)

% We start by mapping the vector |estimates| into the corresponding
% elements in the |Param| structure. We do this using anonymous functions
% that are defined in the structure |Settings|. By construction, |Param.k|
% is a vector of length $\check{n}$. |Param.phi| and |Param.omega| are scalars.

Param.k = Settings.estimates2k(estimates);
Param.phi = Settings.estimates2phi(estimates);
Param.omega = Settings.estimates2omega(estimates);

% Now we use |valueFunctionIteration| to solve the model by
% iterating on the post-survival value function.  We also retrieve |pStay|,
% |pEntry| and |pEntrySet|, which are the probability of certain survival
% and the entry probabilities as described in
% |valueFunctionIteration| above.

[vS,pEntry,pEntrySet,pStay] = valueFunctionIteration(Settings, Param);

% Next we collect the transitions observed in the data and vectorize them.
% The column vectors |from|, |to|, and |demand| are all of length $(\check
% t - 1) \times \check r$.

vec = @(x) x(:);
from = vec(Data.N(1:Settings.tCheck - 1, 1:Settings.rCheck));
to = vec(Data.N(2:Settings.tCheck, 1:Settings.rCheck));
demand = vec(Data.C(2:Settings.tCheck, 1:Settings.rCheck));

% Here and throughout we will
% convert subscripts to linear indices using the Matlab function
% \url{http://www.mathworks.com/help/matlab/ref/sub2ind.html}{sub2ind}.
%
% We store the likelihood contributions in five vectors, each corresponding
% to one of the five cases outlined above. We allocate these vectors here
% and set all of their elements to zero.
llhContributionsCaseI = zeros(size(from));
llhContributionsCaseII = zeros(size(from));
llhContributionsCaseIII = zeros(size(from));
llhContributionsCaseIV = zeros(size(from));
llhContributionsCaseV = zeros(size(from));

% \textbf{Case I:} We store all of the likelihood contributions
% resulting from entry in the vector |llhContributionsCaseI|.
selectMarketsCaseI = to > from;
llhContributionsCaseI(selectMarketsCaseI) = ...
    pEntrySet(sub2ind(size(pEntrySet), ...
                      to(selectMarketsCaseI), ...
                      demand(selectMarketsCaseI)));

% \textbf{Case II:} We store all of the likelihood contributions resulting
% from exit to a non-zero number of firms in the vector
% |llhContributionsCaseII|.
selectMarketsCaseII = from > to & to > 0;
llhContributionsCaseII(selectMarketsCaseII) =  ...
    mixingIntegral(from(selectMarketsCaseII), ...
                   to(selectMarketsCaseII), ...
                   demand(selectMarketsCaseII), ...
                   vS, Param, Settings);
% Note that this case involves computing the integral over mixed strategy
% play, which we do in the function |mixingIntegral|. We document its
% content below.
%
% \textbf{Case III:} We store all of the likelihood contributions resulting
% from transitions to zero (from a positive number of firms) in
% |llhContributionsCaseIII|.
selectMarketsCaseIII = to == 0 & from > 0;
llhContributionsCaseIII(selectMarketsCaseIII) = ...
    1 - pStay(1, demand(selectMarketsCaseIII))' + ...
    mixingIntegral(from(selectMarketsCaseIII), ...
                   to(selectMarketsCaseIII), ...
                   demand(selectMarketsCaseIII), ...
                   vS, Param, Settings);

% \textbf{Case IV:} We store all of the likelihood contributions resulting
% from when the number of active firms remains at zero in
% |llhContributionsCaseIV|.
selectMarketsCaseIV = to == 0 & from == 0;
llhContributionsCaseIV(selectMarketsCaseIV) = ...
    1 - pEntry(1, demand(selectMarketsCaseIV))';

% \textbf{Case V:} We store all of the likelihood contributions resulting
% from the number of firms staying the same in |llhContributionsCaseV|.
selectMarketsCaseV = from == to & to > 0;
llhContributionsCaseV(selectMarketsCaseV) = ...
    pStay(sub2ind(size(pStay), ...
                  from(selectMarketsCaseV), ...
                  demand(selectMarketsCaseV))) - ...
    pEntry(sub2ind(size(pEntry), ...
                   from(selectMarketsCaseV) + 1, ...
                   demand(selectMarketsCaseV)))  + ...
    mixingIntegral(from(selectMarketsCaseV), ...
                   to(selectMarketsCaseV), ...
                   demand(selectMarketsCaseV), ...
                   vS, Param, Settings);

% Finally, we sum up the likelihood contributions from the five cases and
% return the negative log likelihood function. When |ll| is not real
% valued, the negative log likelihood is set to |inf|.

ll = -sum(log(llhContributionsCaseI + ...
              llhContributionsCaseII + ...
              llhContributionsCaseIII + ...
              llhContributionsCaseIV + ...
              llhContributionsCaseV));

if(isnan(ll) || max(real(ll)~=ll) == 1)
    ll = inf;
end

% If two outputs are requested, we also return the likelihood
% contributions:

if(nargout == 2)
    likeCont = llhContributionsCaseI +...
               llhContributionsCaseII +...
               llhContributionsCaseIII +...
               llhContributionsCaseIV +...
               llhContributionsCaseV;
end

% This concludes |likelihoodStep2|.
%
% We still need to specify what exactly happens in the function
% |mixingIntegral|.
%
% \input[2..end]{mixingIntegral.m}

end
