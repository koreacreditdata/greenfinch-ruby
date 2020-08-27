# Greenfinch Ruby Library
![](https://upload.wikimedia.org/wikipedia/commons/3/32/Carduelis_chloris_3_%28Marek_Szczepanek%29.jpg)

한국신용데이터 data lake로 서비스 내 각종 event를 전송하는 ruby library 입니다. 

## 설치하기
```sh
gem install greenfinch-ruby
```

라이브러리 설치 후 발급받은 토큰와 서비스명으로 tracker 생성 후 track 호출로 이벤트 전송

```ruby
tracker = Greenfinch::Tracker.new('<YOUR TOKEN>', '<YOUR SERVICE>', true)
tracker.track('<USER ID>', '<EVENT NAME>')
```

## 사용하기
___
### Greenfinch::Tracker.new
greenfinch tracker를 초기화 하는 함수입니다. 아래와 같이 초기화 후 사용하시기 바랍니다.

```ruby
tracker = Greenfinch::Tracker.new('<YOUR TOKEN>', '<YOUR SERVICE>', true)
```

| Argument | Type | Description |
| ------------- | ------------- | ----- |
| **token** | <span class="mp-arg-type">String, </span></br></span><span class="mp-arg-required">required</span> | 부여받은 token |
| **service_name** | <span class="mp-arg-type">String, </span></br></span><span class="mp-arg-required">required</span> | 부여받은 service name |
| **debug** | <span class="mp-arg-type">Boolean, </span></br></span><span class="mp-arg-required">required</span> | true: staging, false: production |
| **error_handler** | <span class="mp-arg-type">Greenfinch::ErrorHandler, </span></br></span><span class="mp-arg-required">optional</span> | error handler |


___
### Greenfinch::Tracker.track
custom한 event를 전송하는 함수입니다.


```ruby
tracker.track('123456', 'Registered', {Gender: 'Male', Age: 21});
```

| Argument | Type | Description |
| ------------- | ------------- | ----- |
| **user_id** | <span class="mp-arg-type">String, </span></br></span><span class="mp-arg-required">required</span> | user_id |
| **event_name** | <span class="mp-arg-type">String, </span></br></span><span class="mp-arg-required">required</span> | 이벤트 이름 |
| **properties** | <span class="mp-arg-type">Object, </span></br></span><span class="mp-arg-optional">optional</span> | 추가적으로 전송할 properties |

___
### Greenfinch::ErrorHandler
Greenfinch 사용 중 발생하는 에러를 처리합니다. Tracker.new 호출 시 인자로 넘겨 사용하시면 됩니다.


```ruby
require 'logger'

class MyErrorHandler < Greenfinch::ErrorHandler

  def initialize
    @logger = Logger.new('mylogfile.log')
    @logger.level = Logger::ERROR
  end

  def handle(error)
    logger.error "#{error.inspect}\n Backtrace: #{error.backtrace}"
  end

end

my_error_handler = MyErrorHandler.new
tracker = Greenfinch::Tracker.new('<YOUR TOKEN>', '<YOUR SERVICE>', true, my_error_handler)
```
