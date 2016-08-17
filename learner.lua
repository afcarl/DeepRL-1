--
--  Copyright (c) 2016, Horizon Robotics, Inc.
--  All rights reserved.
--
--  This source code is licensed under the MIT license found in the
--  LICENSE file in the root directory of this source tree. An additional grant
--  of patent rights can be found in the PATENTS file in the same directory.
--
--  Author: Yao Zhou, yao.zhou@hobot.cc 
--  

local learner = torch.class('deeprl.learner')

function learner:__init(config)
    self.epoch = config.epoch
    self.env_config = config.env_config
    self.agent_config = config.agent_config
    self.env = deeprl.env(self.env_config)
    self.agent = deeprl.agent(self.agent_config)
    self.epsilon = config.epsilon
end

function learner:run()
    for i = 1, self.epoch do

        -- init environment
        local error = 0
        self.env:reset()
        local game_over = false

        -- init state
        local cur_state = self.env:observe()
        local score = 0

        while game_over ~= true do
            local action
            if math.randf() < self.epsilon then
                action = math.random(1, self.agent_config.n_actions)
            else
                -- forward
                local q = self.agent.policy_net:forward(cur_state)
                local max, idx = torch.max(q, 1)
                action = idx[1]
            end

            if self.epsilon > 0.001 then
                self.epsilon = self.epsilon * 0.999
            end

            local next_state, reward, game_over = self.env:act(action)
            if reward == 1 then score = score + reward * 100 end

            self.agent:remember({
                input_state = cur_state,
                action = action,
                reward = reward,
                next_state = next_state,
                game_over = game_over,
            })

            cur_state = next_state

            -- batch training
            local inputs, targets = self.agent:generate_batch()
            error = error + self.agent:train(inputs, targets)
        end
        utils.printf('Epoch %d : error = %.6f : Score %d', i, error, score)
    end
end

