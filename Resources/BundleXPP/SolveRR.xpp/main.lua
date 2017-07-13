--一、源码声明
	--本脚本算法由 i_82 （Wu Zheng） 编写，仅供爱好者交流与学习使用，严禁用于商业用途。本脚本适用于 iPhone & iPad 的 iOS 5.0 以上环境。

--二、脚本使用说明（要求越狱）
	--1、添加 Cydia 源：http://cydia.touchelf.com，安装触摸精灵后注销。
	--2、将本脚本放置到 /var/touchelf/scripts 目录下，打开触摸精灵并选择本脚本。
	--3、进入天天爱消除，单击开始游戏，然后按音量键启动，运行过程中可以随时按音量键结束运行。

--三、脚本配置说明
	--1、通用游戏配置
		--（1）安静模式：QUIET
		--（2）配置运行延迟：MSEC、BSEC
		--（3）配置方块背景灰度范围：BGMIN、BGMAX
		--（4）配置方块色值范围：M
		--（5）配置区域横纵方格数量：DW、DH
		--（6）配置区域有效范围：CHKINT
	--2、设备自动配置
		--（1）配置坐标系；ROTATE
		--（2）配置区域顶点坐标；X、Y
		--（3）配置方块中心坐标：WI、HE
		--（4）配置方块背景判断坐标：BGX、BGY
		--（5）配置方块尺寸：SW、SH

----------------------------------------------
--以下内容不了解请勿修改，否则脚本很可能无法正常运行。
----------------------------------------------

--初始化子程序
function loadset()
	SCRW, SCRH = getScreenSize();
	SCREEN_RESOLUTION = ""..SCRW.."x"..SCRH.."";
	SCREEN_COLOR_BITS = 32;
	m, n, p, q, timeout, WAIT = 0, 0, 0, 0, 0, 500
	if SCRW == 640 and SCRH == 960 then
		ROTATE, X, Y, DW, DH, SW, SH = 0, 5, 208, 7, 7, 90, 90
	elseif SCRW == 640 and SCRH == 1136 then
		ROTATE, X, Y, DW, DH, SW, SH = 0, 5, 296, 7, 7, 90, 90
	elseif SCRW == 768 and SCRH == 1024 then
		ROTATE, X, Y, DW, DH, SW, SH = 0, 69, 240, 7, 7, 90, 90
	elseif SCRW == 1536 and SCRH == 2048 then
		ROTATE, X, Y, DW, DH, SW, SH = 0, 138, 480, 7, 7, 180, 180
	else
		return false
	end
	init("0",ROTATE);
	return true
end

--主循环程序
function rrprocess()
	for v=1,10000,1 do
		mSleep(WAIT);
		keepScreen(true);
		mt = {}
		for i = 1,DW,1 do
			mt[i] = {}
			for j = 1,DH,1 do
				mt[i][j] = {}
				for k = 1,3,1 do
					mt[i][j][k] = i * j * k
				end
				for a = 1,2,1 do
					if a == 1 then
						mt[i][j][a] = X + SW / 2 * (2 * i - 1)
					else
						mt[i][j][a] = Y + SH / 2 * (2 * j - 1)
					end
				end
				mt[i][j][3] = getColor(mt[i][j][1],mt[i][j][2]);
			end
		end
		keepScreen(false);
		for t1 = 1,DW,1 do
			for t2 = 1,DH,1 do
				r = mt[t1][t2][3]
				s = {}
				for l = 1,8,1 do
					s[l] = 0
				end
				if t1 == 1 then
					if t2 == 1 then
						s[5] = mt[t1 + 1][t2][3]
						s[7] = mt[t1][t2 + 1][3]
						s[8] = mt[t1 + 1][t2 + 1][3]
					else
						if t2 == DH then
							s[2] = mt[t1][t2 - 1][3]
							s[3] = mt[t1 + 1][t2 - 1][3]
							s[5] = mt[t1 + 1][t2][3]
						else
							s[2] = mt[t1][t2 - 1][3]
							s[3] = mt[t1 + 1][t2 - 1][3]
							s[5] = mt[t1 + 1][t2][3]
							s[7] = mt[t1][t2 + 1][3]
							s[8] = mt[t1 + 1][t2 + 1][3]
						end
					end
				else
					if t1 == DW then
						if t2 == 1 then
							s[4] = mt[t1 - 1][t2][3]
							s[6] = mt[t1 - 1][t2 +1][3]
							s[7] = mt[t1][t2 + 1][3]
						else
							if t2 == DH then
								s[1] = mt[t1 - 1][t2 - 1][3]
								s[2] = mt[t1][t2 - 1][3]
								s[4] = mt[t1 - 1][t2][3]
							else
								s[1] = mt[t1 - 1][t2 - 1][3]
								s[2] = mt[t1][t2 - 1][3]
								s[4] = mt[t1 - 1][t2][3]
								s[6] = mt[t1 - 1][t2 +1][3]
								s[7] = mt[t1][t2 + 1][3]
							end
						end
					else
						if t2 == 1 then
							s[4] = mt[t1 - 1][t2][3]
							s[5] = mt[t1 + 1][t2][3]
							s[6] = mt[t1 - 1][t2 +1][3]
							s[7] = mt[t1][t2 + 1][3]
							s[8] = mt[t1 + 1][t2 + 1][3]
						else
							if t2 == DH then
								s[1] = mt[t1 - 1][t2 - 1][3]
								s[2] = mt[t1][t2 - 1][3]
								s[3] = mt[t1 + 1][t2 - 1][3]
								s[4] = mt[t1 - 1][t2][3]
								s[5] = mt[t1 + 1][t2][3]
							else
								s[1] = mt[t1 - 1][t2 - 1][3]
								s[2] = mt[t1][t2 - 1][3]
								s[3] = mt[t1 + 1][t2 - 1][3]
								s[4] = mt[t1 - 1][t2][3]
								s[5] = mt[t1 + 1][t2][3]
								s[6] = mt[t1 - 1][t2 +1][3]
								s[7] = mt[t1][t2 + 1][3]
								s[8] = mt[t1 + 1][t2 + 1][3]
							end
						end
					end
				end
				for h = 1,8,1 do
					if r == s[h] then
						if h == 1 then
							if r == s[3] then
								m = t1
								n = t2
								p = t1
								q = t2 - 1
							end
						else
							if h == 2 then
								if r == s[6] then
									m = t1 - 1
									n = t2 + 1
									p = t1
									q = t2 + 1
								else
									if r == s[8] then
										m = t1 + 1
										n = t2 + 1
										p = t1
										q = t2 + 1
									else
										if t2 > 3 then
											if r == mt[t1][t2 - 3][3] then
												m = t1
												n = t2 - 3
												p = t1
												q = t2 - 2
											end
										end
									end
								end
							else
								if h == 3 then
									if r == s[8] then
										m = t1
										n = t2
										p = t1 + 1
										q = t2
									end
								else
									if h == 4 then
										if r == s[3] then
											m = t1 + 1
											n = t2 - 1
											p = t1 + 1
											q = t2
										else
											if r == s[8] then
												m = t1 + 1
												n = t2 + 1
												p = t1 + 1
												q = t2
											else
												if t1 > 3 then
													if r == mt[t1 - 3][t2][3] then
														m = t1 - 3
														n = t2
														p = t1 - 2
														q = t2
													end
												end
											end
										end
									else
										if h == 5 then
											if r == s[1] then
												m = t1 - 1
												n = t2 - 1
												p = t1 - 1
												q = t2
											else
												if r == s[6] then
													m = t1 - 1
													n = t2 + 1
													p = t1 - 1
													q = t2
												else
													if t1 < DW - 2 then
														if r == mt[t1 + 3][t2][3] then
															m = t1 + 3
															n = t2
															p = t1 + 2
															q = t2
														end
													end
												end
											end
										else
											if h == 6 then
												if r == s[1] then
													m = t1
													n = t2
													p = t1 - 1
													q = t2
												end
											else
												if h == 7 then
													if r == s[1] then
														m = t1 - 1
														n = t2 - 1
														p = t1
														q = t2 - 1
													else
														if r == s[3] then
															m = t1 + 1
															n = t2 - 1
															p = t1
															q = t2 - 1 
														else
															if t2 < DH - 2 then
																if r == mt[t1][t2 + 3][3] then
																	m = t1
																	n = t2 + 3
																	p = t1
																	q = t2 + 2
																end
															end
														end
													end
												else
													if h == 8 then
														if r == s[6] then
															m = t1
															n = t2
															p = t1
															q = t2 + 1
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
		if m >= 1 and n >=1 and p >= 1 and q >=1 and m <= DW and n <= DH and p <= DW and q <= DH then
			x1, y1 = math.random(mt[m][n][1] - 5, mt[m][n][1] + 5), math.random(mt[m][n][2] - 5, mt[m][n][2] + 5);
			x2, y2 = math.random(mt[p][q][1] - 5, mt[p][q][1] + 5), math.random(mt[p][q][2] - 5, mt[p][q][2] + 5);
			touchDown(1,x1,y1);
			mSleep(math.random(10,40));
			touchMove(1,math.ceil((x2+x1)/2),math.ceil((y2+y1)/2));
			mSleep(math.random(10,40));
			touchUp(1,x2,y2);
		else
			if timeout >= 3 then
				dialog("未检测到游戏界面，请进入游戏后再运行脚本。",5);
				break
			else
				timeout = timeout + 1;
				m, n, p, q = 0, 0, 0, 0;
				mSleep(1000);
			end
		end
	end
end

--启动脚本
	ret = loadset();
	if ret == true then
		dialog("天天爱消除刷分脚本 1.3.0 For TouchSprite\n作者：i_82（QQ：357722984）\n仅供爱好者交流与学习使用，严禁用于商业用途。\nP.S. 把他人劳动成果拿去卖的，小心吃饭噎死喝水呛死！\n威锋网测试组出品",0);
		mSleep(5000);
		rrprocess();
	end
