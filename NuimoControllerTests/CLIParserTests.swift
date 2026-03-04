import Testing
@testable import NuimoController

struct CLIParserTests {

    @Test func defaultOptionsWhenNoArguments() {
        let opts = CLIParser.parse(["NuimoController"])
        #expect(opts.verbose == false)
        #expect(opts.configPath == nil)
    }

    @Test func verboseLongFlag() {
        let opts = CLIParser.parse(["NuimoController", "--verbose"])
        #expect(opts.verbose == true)
    }

    @Test func verboseShortFlag() {
        let opts = CLIParser.parse(["NuimoController", "-v"])
        #expect(opts.verbose == true)
    }

    @Test func configLongFlag() {
        let opts = CLIParser.parse(["NuimoController", "--config", "/tmp/test.yaml"])
        #expect(opts.configPath == "/tmp/test.yaml")
    }

    @Test func configShortFlag() {
        let opts = CLIParser.parse(["NuimoController", "-c", "/tmp/test.yaml"])
        #expect(opts.configPath == "/tmp/test.yaml")
    }

    @Test func combinedFlags() {
        let opts = CLIParser.parse(["NuimoController", "--verbose", "--config", "/tmp/test.yaml"])
        #expect(opts.verbose == true)
        #expect(opts.configPath == "/tmp/test.yaml")
    }

    @Test func configFlagWithoutValueIgnored() {
        let opts = CLIParser.parse(["NuimoController", "--config"])
        #expect(opts.configPath == nil)
    }

    @Test func unknownFlagsIgnored() {
        let opts = CLIParser.parse(["NuimoController", "--unknown", "value"])
        #expect(opts.verbose == false)
        #expect(opts.configPath == nil)
    }
}
