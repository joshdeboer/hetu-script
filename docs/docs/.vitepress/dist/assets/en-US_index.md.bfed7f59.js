import{o as n,c as a,a as t}from"./app.c9011ed2.js";const s='{"title":"Hetu Script","description":"","frontmatter":{},"headers":[{"level":2,"title":"Warning","slug":"warning"},{"level":2,"title":"Introduction","slug":"introduction"},{"level":2,"title":"Quick start","slug":"quick-start"},{"level":2,"title":"Binding","slug":"binding"},{"level":2,"title":"Command line tool","slug":"command-line-tool"},{"level":2,"title":"Referrences:","slug":"referrences"},{"level":2,"title":"Apps that embedded Hetu:","slug":"apps-that-embedded-hetu"}],"relativePath":"en-US/index.md","lastUpdated":1625730398918}',e={},p=t('<h1 id="hetu-script"><a class="header-anchor" href="#hetu-script" aria-hidden="true">#</a> Hetu Script</h1><h2 id="warning"><a class="header-anchor" href="#warning" aria-hidden="true">#</a> Warning</h2><p><strong>Hetu is early WIP! We are focusing on making Hetu stable and feature complete right now.</strong></p><p>Discussion group:</p><p>Discord: <a href="https://discord.gg/Q8JWQYEw" target="_blank" rel="noopener noreferrer">https://discord.gg/Q8JWQYEw</a></p><p>QQ 群: 812529118</p><h2 id="introduction"><a class="header-anchor" href="#introduction" aria-hidden="true">#</a> Introduction</h2><p>Hetu is a lightweight script language purely written in Dart for embedding in Flutter apps. The main goal is to enable Flutter app have hotfix and scripting ability.</p><p>We did not choose to use another existing language to achieve the goal. Because we want to keep the language simple, and keep it away from interference of other language&#39;s complex implementation and their irrelative-to-Flutter eco-system, and make the debug process pain-free and remain in Dart realms.</p><p>It takes very little time to bind almost anything in Dart/Flutter into Hetu and use similar grammar to write your app. And to communicate with classes &amp; functions in Dart is very easy.</p><h2 id="quick-start"><a class="header-anchor" href="#quick-start" aria-hidden="true">#</a> Quick start</h2><p>Hetu&#39;s grammar is close to typescript/kotlin/swift and other modern languages, need very little time to get familar with.</p><ul><li>Optional semicolon.</li><li>Function is declared with &#39;fun, get, set, construct&#39;.</li><li>Optional type annotation. Variable declared will infer its type from its initializer expression.</li></ul><p><a href="https://github.com/hetu-script/site-www/blob/main/docs/en-US/syntax/index.md" target="_blank" rel="noopener noreferrer">Syntax referrence</a></p><p>In your Dart code, you can interpret a script file:</p><div class="language-typescript"><pre><code><span class="token keyword">import</span> <span class="token string">&#39;package:hetu_script/hetu_script.dart&#39;</span><span class="token punctuation">;</span>\n\n<span class="token keyword">void</span> <span class="token function">main</span><span class="token punctuation">(</span><span class="token punctuation">)</span> <span class="token punctuation">{</span>\n  <span class="token keyword">var</span> hetu <span class="token operator">=</span> <span class="token function">Hetu</span><span class="token punctuation">(</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n  hetu<span class="token punctuation">.</span><span class="token function">init</span><span class="token punctuation">(</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n  hetu<span class="token punctuation">.</span><span class="token function">evalFile</span><span class="token punctuation">(</span><span class="token string">&#39;hello.ht&#39;</span><span class="token punctuation">,</span> invokeFunc<span class="token operator">:</span> <span class="token string">&#39;main&#39;</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n<span class="token punctuation">}</span>\n</code></pre></div><p>While [<a href="http://hello.ht" target="_blank" rel="noopener noreferrer">hello.ht</a>] is the script file written in Hetu, here is an example:</p><div class="language-typescript"><pre><code><span class="token comment">// Define a class.</span>\n<span class="token keyword">class</span> <span class="token class-name">Person</span> <span class="token punctuation">{</span>\n  <span class="token keyword">var</span> name<span class="token operator">:</span> str\n  <span class="token function">construct</span> <span class="token punctuation">(</span>name<span class="token operator">:</span> str<span class="token punctuation">)</span> <span class="token punctuation">{</span>\n    <span class="token keyword">this</span><span class="token punctuation">.</span>name <span class="token operator">=</span> name\n  <span class="token punctuation">}</span>\n  fun greeting <span class="token punctuation">{</span>\n    <span class="token function">print</span><span class="token punctuation">(</span><span class="token string">&#39;Hi! I\\&#39;m&#39;</span><span class="token punctuation">,</span> name<span class="token punctuation">)</span>\n  <span class="token punctuation">}</span>\n<span class="token punctuation">}</span>\n\n<span class="token comment">// This is where the script starts executing.</span>\nfun main <span class="token punctuation">{</span>\n  <span class="token keyword">var</span> ht <span class="token operator">=</span> <span class="token function">Person</span><span class="token punctuation">(</span><span class="token string">&#39;Hetu&#39;</span><span class="token punctuation">)</span>\n  ht<span class="token punctuation">.</span><span class="token function">greeting</span><span class="token punctuation">(</span><span class="token punctuation">)</span>\n<span class="token punctuation">}</span>\n</code></pre></div><h2 id="binding"><a class="header-anchor" href="#binding" aria-hidden="true">#</a> Binding</h2><p>Hetu script is purely written in Dart, so passing object to and from script is extremely easy.</p><p>Check <a href="https://github.com/hetu-script/site-www/blob/main/docs/en-US/binding/index.md" target="_blank" rel="noopener noreferrer">this page</a> for more information about how to bind external classes, functions, enums and how to passing object and functions between Dart and script.</p><div class="language-dart"><pre><code><span class="token keyword">import</span> <span class="token string">&#39;package:hetu_script/hetu_script.dart&#39;</span><span class="token punctuation">;</span>\n\n<span class="token keyword">void</span> <span class="token function">main</span><span class="token punctuation">(</span><span class="token punctuation">)</span> <span class="token punctuation">{</span>\n  <span class="token keyword">var</span> hetu <span class="token operator">=</span> <span class="token function">Hetu</span><span class="token punctuation">(</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n  hetu<span class="token punctuation">.</span><span class="token function">init</span><span class="token punctuation">(</span>externalFunctions<span class="token punctuation">:</span> <span class="token punctuation">{</span>\n    <span class="token string">&#39;hello&#39;</span><span class="token punctuation">:</span> <span class="token punctuation">(</span><span class="token punctuation">)</span> <span class="token operator">=</span><span class="token operator">&gt;</span> <span class="token punctuation">{</span><span class="token string">&#39;greeting&#39;</span><span class="token punctuation">:</span> <span class="token string">&#39;hello&#39;</span><span class="token punctuation">}</span><span class="token punctuation">,</span>\n  <span class="token punctuation">}</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n  hetu<span class="token punctuation">.</span><span class="token function">eval</span><span class="token punctuation">(</span><span class="token string">r&#39;&#39;&#39;\n      external fun hello\n      fun main {\n        var dartValue = hello()\n        print(&#39;dart value:&#39;, dartValue)\n        dartValue[&#39;foo&#39;] = &#39;bar&#39;\n        return dartValue\n      }&#39;&#39;&#39;</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n\n  <span class="token keyword">var</span> hetuValue <span class="token operator">=</span> hetu<span class="token punctuation">.</span><span class="token function">invoke</span><span class="token punctuation">(</span><span class="token string">&#39;main&#39;</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n\n  <span class="token function">print</span><span class="token punctuation">(</span><span class="token string">&#39;hetu value: $hetuValue&#39;</span><span class="token punctuation">)</span><span class="token punctuation">;</span>\n<span class="token punctuation">}</span>\n</code></pre></div><h2 id="command-line-tool"><a class="header-anchor" href="#command-line-tool" aria-hidden="true">#</a> Command line tool</h2><p>Hetu has a command line REPL tool for testing. You can activate by the following command:</p><div class="language-"><pre><code>dart pub global activate hetu_script\n</code></pre></div><p>Then you can use command line tool &#39;hetu&#39; in any directory on your computer. (If you are facing any problems, please check this official document about <a href="https://dart.dev/tools/pub/cmd/pub-global" target="_blank" rel="noopener noreferrer">pub global activate</a>)</p><p>More information can be found by enter [hetu -h].</p><p>If no command and option is provided, enter REPL mode.</p><p>In REPL mode, every exrepssion you entered will be evaluated and print out immediately.</p><p>If you want to write multiple line in REPL mode, use &#39;\\&#39; to end a line.</p><div class="language-typescript"><pre><code><span class="token operator">&gt;&gt;&gt;</span><span class="token keyword">var</span> a <span class="token operator">=</span> <span class="token number">42</span>\n<span class="token operator">&gt;&gt;&gt;</span>a\n<span class="token number">42</span>\n<span class="token operator">&gt;&gt;&gt;</span>fun hello <span class="token punctuation">{</span>\\\n<span class="token keyword">return</span> a <span class="token punctuation">}</span>\n<span class="token operator">&gt;&gt;&gt;</span>hello\nfun <span class="token function">hello</span><span class="token punctuation">(</span><span class="token punctuation">)</span> <span class="token operator">-</span><span class="token operator">&gt;</span> <span class="token builtin">any</span> <span class="token comment">// repl print</span>\n<span class="token operator">&gt;&gt;&gt;</span><span class="token function">hello</span><span class="token punctuation">(</span><span class="token punctuation">)</span>\n<span class="token number">42</span> <span class="token comment">// repl print</span>\n<span class="token operator">&gt;&gt;&gt;</span>\n</code></pre></div><h2 id="referrences"><a class="header-anchor" href="#referrences" aria-hidden="true">#</a> Referrences:</h2><ul><li><a href="https://github.com/hetu-script/site-www/blob/main/docs/en-US/operator_precedence/index.md" target="_blank" rel="noopener noreferrer">Operator precedence</a></li><li><a href="https://github.com/hetu-script/site-www/blob/main/docs/en-US/bytecode_specification/index.md" target="_blank" rel="noopener noreferrer">Bytecode specification</a></li></ul><h2 id="apps-that-embedded-hetu"><a class="header-anchor" href="#apps-that-embedded-hetu" aria-hidden="true">#</a> Apps that embedded Hetu:</h2><table><thead><tr><th style="text-align:left;">Name</th><th style="text-align:left;">Author</th><th style="text-align:left;">Description</th><th style="text-align:center;">Download</th><th style="text-align:left;">Source</th></tr></thead><tbody><tr><td style="text-align:left;">Monster Hunter Otomo: Rise</td><td style="text-align:left;"><a href="https://github.com/rockingdice" target="_blank" rel="noopener noreferrer">rockingdice</a></td><td style="text-align:left;">A unofficial game companion app for Capcom&#39;s Monster Hunter: Rise</td><td style="text-align:center;"><a href="https://apps.apple.com/cn/app/id1561983275" target="_blank" rel="noopener noreferrer">iOS</a></td><td style="text-align:left;">Closed Source</td></tr></tbody></table>',35);e.render=function(t,s,e,o,i,c){return n(),a("div",null,[p])};export default e;export{s as __pageData};
