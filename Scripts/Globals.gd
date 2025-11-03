extends Node

var presets := [
	"G330308",
	"G333674",
	"G337426",
	"G338000",
	"G344656",
	"G350491",
	"G357197",
	"G361407"
]

var lat_obs = [0.62267336022, 0.76151183984, 0.76151183984, 0.91184982752, 0.81079526383, 0.81079526383, 0.53342313506, 0.59637900541, 0.53079879206, 0.79156499342, 0.81070543755, -0.5573418078, 0.7299645671, 0.0, 0.6355068497, 0.34231676739, 0.76151183984, 0.7629930799, 0.76270463257, 0.76270463257]
var long_obs = [2.43536359469, 0.18333805213, 0.18333805213, 0.17116780435, -2.08405676917, -2.08405676917, -1.58430937078, -2.06175744538, -1.59137068496, 0.20853775679, 0.10821041362, 2.02138216202, 0.22117684946, 0.0, 2.396441015, 1.34444215058, 0.18333805213, 0.1840585887, 0.1819299673, 0.1819299673]
var name_obs = ['T1', 'V0', 'V1', 'G1', 'H2', 'H1', 'L1', 'C1', 'A1', 'O1', 'X1', 'B1', 'N1', 'U1', 'K1', 'I1', 'E1', 'E2', 'E3', 'E0']
var hated_ones = ['U1', 'V0', 'E1', 'H2', 'A1', 'E2', 'E3', 'E0']
var init_on = ['H1', 'L1', 'I1', 'V1', 'K1']
var detectors_on = [] # populated before call to load_prob_file

func _ready():
	return

func load_prob_file():
	var detector_string = " ".join(Globals.detectors_on)
	var output = []
	var gpath = ProjectSettings.globalize_path("res://Assets")
	OS.execute("wsl", ["/home/ryon/bayestar/init.sh", gpath, detector_string], output)
	return output
