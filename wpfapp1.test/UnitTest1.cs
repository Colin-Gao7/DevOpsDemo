using WpfApp1;

namespace wpfapp1.test
{
    public class UnitTest1
    {
        [Fact]
        public void Test1()
        {
            var main = new justTest();
            var res = main.justForTest();
            Assert.Equal("test ok.", res);
        }
        
    }
}